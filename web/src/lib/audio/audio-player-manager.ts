import Hls from "hls.js";
import type { Episode } from "@/types/content";
import {
  useAudioPlayerStore,
  type PlaybackSpeed,
} from "@/stores/audio-player-store";
import { useProgressStore } from "@/stores/progress-store";
import { throttle } from "@/lib/utils/throttle";

/**
 * Singleton audio player manager using HLS.js
 * Manages audio playback, HLS streaming, and state synchronization
 *
 * Architecture:
 * - Detects native HLS support (Safari) vs hls.js (Chrome/Firefox/Edge)
 * - Integrates with Zustand stores for state management
 * - Throttled progress updates every 1000ms
 * - Automatic progress persistence
 */
export class AudioPlayerManager {
  private static instance: AudioPlayerManager | null = null;

  private audio: HTMLAudioElement;
  private hls: Hls | null = null;
  private currentEpisode: Episode | null = null;
  private progressUpdateInterval: ReturnType<typeof setInterval> | null = null;
  private isLoading: boolean = false; // PAL Fix #2: Prevent race conditions
  private networkRetryCount: number = 0; // PAL Fix #3: Track retry attempts
  private readonly MAX_NETWORK_RETRIES = 3;

  // Throttled progress update (1000ms)
  private throttledProgressUpdate: ReturnType<typeof throttle>;

  // PAL Fix #1: Store bound event handlers for proper cleanup
  private boundHandlers = {
    loadedmetadata: this.handleLoadedMetadata.bind(this),
    playing: this.handlePlaying.bind(this),
    pause: this.handlePause.bind(this),
    waiting: this.handleWaiting.bind(this),
    canplay: this.handleCanPlay.bind(this),
    ended: this.handleEnded.bind(this),
    error: this.handleError.bind(this),
    timeupdate: this.handleTimeUpdate.bind(this),
    ratechange: this.handleRateChange.bind(this),
  };

  private constructor() {
    this.audio = new Audio();
    this.setupAudioListeners();

    // Throttle progress updates to 1000ms
    this.throttledProgressUpdate = throttle(() => {
      this.updateProgress();
    }, 1000);
  }

  /**
   * Get singleton instance
   * Only creates instance in browser environment (not during SSR)
   */
  static getInstance(): AudioPlayerManager {
    // Check if we're in a browser environment
    if (typeof window === "undefined") {
      throw new Error(
        "AudioPlayerManager can only be used in browser environment",
      );
    }

    if (!AudioPlayerManager.instance) {
      AudioPlayerManager.instance = new AudioPlayerManager();
    }
    return AudioPlayerManager.instance;
  }

  /**
   * Setup audio element event listeners
   * PAL Fix #1: Using bound handlers for proper cleanup
   */
  private setupAudioListeners(): void {
    this.audio.addEventListener(
      "loadedmetadata",
      this.boundHandlers.loadedmetadata,
    );
    this.audio.addEventListener("playing", this.boundHandlers.playing);
    this.audio.addEventListener("pause", this.boundHandlers.pause);
    this.audio.addEventListener("waiting", this.boundHandlers.waiting);
    this.audio.addEventListener("canplay", this.boundHandlers.canplay);
    this.audio.addEventListener("ended", this.boundHandlers.ended);
    this.audio.addEventListener("error", this.boundHandlers.error);
    this.audio.addEventListener("timeupdate", this.boundHandlers.timeupdate);
    this.audio.addEventListener("ratechange", this.boundHandlers.ratechange);
  }

  /**
   * Event handler: Duration loaded
   */
  private handleLoadedMetadata(): void {
    const store = useAudioPlayerStore.getState();
    store.updateDuration(this.audio.duration);
  }

  /**
   * Event handler: Playback started
   */
  private handlePlaying(): void {
    const store = useAudioPlayerStore.getState();
    store.updateState("playing");
    this.startProgressTracking();
    this.networkRetryCount = 0; // Reset retry count on successful playback
  }

  /**
   * Event handler: Playback paused
   */
  private handlePause(): void {
    const store = useAudioPlayerStore.getState();
    if (!this.audio.ended) {
      store.updateState("paused");
    }
    this.stopProgressTracking();
    this.updateProgress(); // Save immediately on pause
  }

  /**
   * Event handler: Loading/buffering
   */
  private handleWaiting(): void {
    const store = useAudioPlayerStore.getState();
    if (store.playbackState === "playing") {
      store.updateState("loading");
    }
  }

  /**
   * Event handler: Can play (buffering complete)
   */
  private handleCanPlay(): void {
    const store = useAudioPlayerStore.getState();
    if (store.playbackState === "loading") {
      store.updateState("playing");
    }
  }

  /**
   * Event handler: Playback ended
   */
  private handleEnded(): void {
    const store = useAudioPlayerStore.getState();
    store.onPlaybackCompleted();
    this.stopProgressTracking();
    this.updateProgress(); // Save final progress
  }

  /**
   * Event handler: Error occurred
   */
  private handleError(): void {
    const store = useAudioPlayerStore.getState();
    const error = this.audio.error;
    let errorMessage = "Playback error";

    if (error) {
      switch (error.code) {
        case MediaError.MEDIA_ERR_ABORTED:
          errorMessage = "Playback aborted";
          break;
        case MediaError.MEDIA_ERR_NETWORK:
          errorMessage = "Network error";
          break;
        case MediaError.MEDIA_ERR_DECODE:
          errorMessage = "Audio decode error";
          break;
        case MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED:
          errorMessage = "Audio format not supported";
          break;
      }
    }

    store.setError(errorMessage);
    this.stopProgressTracking();
  }

  /**
   * Event handler: Time update (position changes)
   */
  private handleTimeUpdate(): void {
    const store = useAudioPlayerStore.getState();
    store.updatePosition(this.audio.currentTime);
    this.throttledProgressUpdate();
  }

  /**
   * Event handler: Speed change
   */
  private handleRateChange(): void {
    const store = useAudioPlayerStore.getState();
    store.updateSpeed(this.audio.playbackRate as PlaybackSpeed);
  }

  /**
   * Check if browser supports native HLS
   */
  private supportsNativeHLS(): boolean {
    return Boolean(
      this.audio.canPlayType("application/vnd.apple.mpegurl") ||
        this.audio.canPlayType("audio/mpegurl"),
    );
  }

  /**
   * Load episode and prepare for playback
   * PAL Fix #2: Prevent race conditions with isLoading guard
   */
  async loadEpisode(episode: Episode): Promise<void> {
    const store = useAudioPlayerStore.getState();
    const progressStore = useProgressStore.getState();

    // Prevent overlapping loads
    if (this.isLoading) {
      console.warn("Episode load already in progress, skipping");
      return;
    }

    // Skip if same episode already loaded
    if (this.currentEpisode?.id === episode.id) {
      console.log("Episode already loaded");
      return;
    }

    this.isLoading = true;

    try {
      store.updateState("loading");
      store.setCurrentEpisode(episode);
      this.currentEpisode = episode;

      // Get streaming URL
      const streamingUrl = episode.streaming_urls?.m3u8;
      if (!streamingUrl) {
        throw new Error("No streaming URL available");
      }

      // Clean up previous HLS instance
      if (this.hls) {
        this.hls.destroy();
        this.hls = null;
      }

      // Check for native HLS support (Safari)
      if (this.supportsNativeHLS()) {
        console.log("Using native HLS support");
        this.audio.src = streamingUrl;
      } else if (Hls.isSupported()) {
        console.log("Using hls.js");
        this.hls = new Hls({
          debug: false,
          enableWorker: true,
          lowLatencyMode: false,
        });

        // Setup HLS event listeners
        // PAL Fix #3: Network error recovery with exponential backoff
        this.hls.on(Hls.Events.ERROR, (event, data) => {
          console.error("HLS error:", data);

          if (data.fatal) {
            switch (data.type) {
              case Hls.ErrorTypes.NETWORK_ERROR:
                // Implement retry with exponential backoff
                if (this.networkRetryCount < this.MAX_NETWORK_RETRIES) {
                  this.networkRetryCount++;
                  const delay = Math.pow(2, this.networkRetryCount) * 1000; // 2s, 4s, 8s

                  console.log(
                    `Network error. Retry ${this.networkRetryCount}/${this.MAX_NETWORK_RETRIES} in ${delay}ms`,
                  );

                  setTimeout(() => {
                    console.log("Retrying network load...");
                    this.hls?.startLoad();
                  }, delay);
                } else {
                  console.error("Max network retries reached");
                  store.setError(
                    "Network error loading stream. Please check your connection.",
                  );
                  this.networkRetryCount = 0;
                }
                break;
              case Hls.ErrorTypes.MEDIA_ERROR:
                // Try to recover from media error
                console.log("Attempting to recover from media error");
                this.hls?.recoverMediaError();
                break;
              default:
                store.setError("Fatal streaming error");
                break;
            }
          }
        });

        this.hls.loadSource(streamingUrl);
        this.hls.attachMedia(this.audio);
      } else {
        throw new Error(
          "HLS not supported in this browser. Please use Safari, Chrome, or Firefox.",
        );
      }

      // Get resume position from progress tracker
      const resumePosition = progressStore.getResumePosition(episode.id);
      if (resumePosition > 0) {
        this.audio.currentTime = resumePosition;
      }

      // Apply current playback speed
      this.audio.playbackRate = store.playbackSpeed;

      // Wait for canplay event before starting
      await new Promise<void>((resolve, reject) => {
        const handleCanPlay = () => {
          this.audio.removeEventListener("canplay", handleCanPlay);
          this.audio.removeEventListener("error", handleError);
          resolve();
        };

        const handleError = () => {
          this.audio.removeEventListener("canplay", handleCanPlay);
          this.audio.removeEventListener("error", handleError);
          reject(new Error("Failed to load audio"));
        };

        this.audio.addEventListener("canplay", handleCanPlay, { once: true });
        this.audio.addEventListener("error", handleError, { once: true });
      });
    } catch (error) {
      const message =
        error instanceof Error ? error.message : "Failed to load episode";
      store.setError(message);
      throw error;
    } finally {
      // PAL Fix #2: Always release the loading lock
      this.isLoading = false;
    }
  }

  /**
   * Play current episode or load new episode and play
   */
  async play(episode?: Episode): Promise<void> {
    try {
      if (episode && episode.id !== this.currentEpisode?.id) {
        await this.loadEpisode(episode);
      }

      await this.audio.play();
    } catch (error) {
      const store = useAudioPlayerStore.getState();
      const message =
        error instanceof Error ? error.message : "Playback failed";
      store.setError(message);
      throw error;
    }
  }

  /**
   * Pause playback
   */
  pause(): void {
    this.audio.pause();
  }

  /**
   * Seek to position (seconds)
   */
  seek(position: number): void {
    this.audio.currentTime = position;
    this.updateProgress(); // Save immediately on seek
  }

  /**
   * Set playback speed
   */
  setSpeed(speed: PlaybackSpeed): void {
    this.audio.playbackRate = speed;
  }

  /**
   * Skip forward
   */
  skipForward(seconds: number = 30): void {
    const newPosition = Math.min(
      this.audio.currentTime + seconds,
      this.audio.duration,
    );
    this.seek(newPosition);
  }

  /**
   * Skip backward
   */
  skipBackward(seconds: number = 15): void {
    const newPosition = Math.max(this.audio.currentTime - seconds, 0);
    this.seek(newPosition);
  }

  /**
   * Stop playback and reset
   */
  stop(): void {
    this.audio.pause();
    this.audio.currentTime = 0;
    this.stopProgressTracking();

    if (this.hls) {
      this.hls.destroy();
      this.hls = null;
    }

    this.currentEpisode = null;
    useAudioPlayerStore.getState().reset();
  }

  /**
   * Start progress tracking interval
   */
  private startProgressTracking(): void {
    if (this.progressUpdateInterval) {
      return;
    }

    // Update every 1000ms
    this.progressUpdateInterval = setInterval(() => {
      this.updateProgress();
    }, 1000);
  }

  /**
   * Stop progress tracking interval
   */
  private stopProgressTracking(): void {
    if (this.progressUpdateInterval) {
      clearInterval(this.progressUpdateInterval);
      this.progressUpdateInterval = null;
    }
  }

  /**
   * Update progress in store
   */
  private updateProgress(): void {
    if (!this.currentEpisode) {
      return;
    }

    const progressStore = useProgressStore.getState();
    progressStore.updateProgress(
      this.currentEpisode.id,
      this.audio.currentTime,
      this.audio.duration,
    );
  }

  /**
   * Get audio element (for advanced use cases)
   */
  getAudioElement(): HTMLAudioElement {
    return this.audio;
  }

  /**
   * Cleanup resources
   * PAL Fix #1: Use bound handlers for proper cleanup
   */
  destroy(): void {
    this.stop();

    // Remove event listeners using bound handlers
    this.audio.removeEventListener(
      "loadedmetadata",
      this.boundHandlers.loadedmetadata,
    );
    this.audio.removeEventListener("playing", this.boundHandlers.playing);
    this.audio.removeEventListener("pause", this.boundHandlers.pause);
    this.audio.removeEventListener("waiting", this.boundHandlers.waiting);
    this.audio.removeEventListener("canplay", this.boundHandlers.canplay);
    this.audio.removeEventListener("ended", this.boundHandlers.ended);
    this.audio.removeEventListener("error", this.boundHandlers.error);
    this.audio.removeEventListener("timeupdate", this.boundHandlers.timeupdate);
    this.audio.removeEventListener("ratechange", this.boundHandlers.ratechange);

    if (this.hls) {
      this.hls.destroy();
      this.hls = null;
    }

    AudioPlayerManager.instance = null;
  }
}

/**
 * Get audio player manager instance
 * Safe to use in browser environment only
 * Use inside useEffect or event handlers, not at module level
 */
export function getAudioPlayerManager(): AudioPlayerManager {
  return AudioPlayerManager.getInstance();
}
