import { create } from "zustand";
import type { Episode } from "@/types/content";
import { formatDuration } from "@/lib/utils/format-duration";

/**
 * Playback states matching Flutter's AppPlaybackState
 */
export type PlaybackState =
  | "stopped"
  | "playing"
  | "paused"
  | "loading"
  | "completed"
  | "error";

/**
 * Playback speed options
 */
export const PLAYBACK_SPEEDS = [1.0, 1.25, 1.5, 2.0] as const;
export type PlaybackSpeed = (typeof PLAYBACK_SPEEDS)[number];

/**
 * Audio player store state
 */
interface AudioPlayerState {
  // Current episode
  currentEpisode: Episode | null;

  // Playback state
  playbackState: PlaybackState;
  currentPosition: number; // seconds
  totalDuration: number; // seconds
  playbackSpeed: PlaybackSpeed;
  errorMessage: string | null;

  // Computed properties (getters)
  isPlaying: () => boolean;
  isPaused: () => boolean;
  isLoading: () => boolean;
  hasError: () => boolean;
  isIdle: () => boolean;
  isCompleted: () => boolean;
  progress: () => number; // 0-1
  formattedCurrentPosition: () => string;
  formattedTotalDuration: () => string;

  // Actions (will be implemented by audio manager)
  play: (episode?: Episode) => Promise<void>;
  pause: () => void;
  seek: (position: number) => void;
  setSpeed: (speed: PlaybackSpeed) => void;
  skipForward: (seconds?: number) => void;
  skipBackward: (seconds?: number) => void;
  stop: () => void;

  // State updates (called by audio manager)
  updateState: (state: PlaybackState) => void;
  updatePosition: (position: number) => void;
  updateDuration: (duration: number) => void;
  updateSpeed: (speed: PlaybackSpeed) => void;
  setError: (error: string) => void;
  clearError: () => void;
  onPlaybackCompleted: () => void;
  reset: () => void;
  setCurrentEpisode: (episode: Episode | null) => void;
}

/**
 * Audio player store for managing playback state
 *
 * Implements Flutter's PlayerStateNotifier logic:
 * - State machine: stopped → loading → playing ⇄ paused → completed
 * - Position/duration tracking
 * - Playback speed control
 * - Error handling
 */
export const useAudioPlayerStore = create<AudioPlayerState>((set, get) => ({
  // Initial state
  currentEpisode: null,
  playbackState: "stopped",
  currentPosition: 0,
  totalDuration: 0,
  playbackSpeed: 1.0,
  errorMessage: null,

  // Computed properties
  isPlaying: () => get().playbackState === "playing",
  isPaused: () => get().playbackState === "paused",
  isLoading: () => get().playbackState === "loading",
  hasError: () => get().playbackState === "error",
  isIdle: () => get().playbackState === "stopped",
  isCompleted: () => get().playbackState === "completed",

  progress: () => {
    const { currentPosition, totalDuration } = get();
    if (totalDuration <= 0) return 0;
    const result = currentPosition / totalDuration;
    return Math.max(0, Math.min(1, result)); // Clamp 0-1
  },

  formattedCurrentPosition: () => {
    return formatDuration(get().currentPosition);
  },

  formattedTotalDuration: () => {
    return formatDuration(get().totalDuration);
  },

  // Actions (placeholders - will be implemented by HLS manager)
  play: async (episode?: Episode) => {
    if (episode) {
      set({
        currentEpisode: episode,
        playbackState: "loading",
        errorMessage: null,
      });
    } else {
      set({ playbackState: "playing" });
    }
    // Actual implementation will be in audio-player-manager.ts
  },

  pause: () => {
    set({ playbackState: "paused" });
    // Actual implementation will be in audio-player-manager.ts
  },

  seek: (position: number) => {
    set({ currentPosition: position });
    // Actual implementation will be in audio-player-manager.ts
  },

  setSpeed: (speed: PlaybackSpeed) => {
    set({ playbackSpeed: speed });
    // Actual implementation will be in audio-player-manager.ts
  },

  skipForward: (seconds = 30) => {
    const { currentPosition, totalDuration } = get();
    const newPosition = Math.min(currentPosition + seconds, totalDuration);
    set({ currentPosition: newPosition });
    // Actual implementation will be in audio-player-manager.ts
  },

  skipBackward: (seconds = 15) => {
    const { currentPosition } = get();
    const newPosition = Math.max(currentPosition - seconds, 0);
    set({ currentPosition: newPosition });
    // Actual implementation will be in audio-player-manager.ts
  },

  stop: () => {
    set({
      playbackState: "stopped",
      currentPosition: 0,
      errorMessage: null,
    });
    // Actual implementation will be in audio-player-manager.ts
  },

  // State updates (called by audio manager)
  updateState: (state: PlaybackState) => {
    set((prev) => {
      // Clear error when transitioning away from error state
      const errorMessage =
        state !== "error" && prev.errorMessage !== null
          ? null
          : prev.errorMessage;

      return {
        playbackState: state,
        errorMessage,
      };
    });
  },

  updatePosition: (position: number) => {
    if (get().currentPosition !== position) {
      set({ currentPosition: position });
    }
  },

  updateDuration: (duration: number) => {
    if (get().totalDuration !== duration) {
      set({ totalDuration: duration });
    }
  },

  updateSpeed: (speed: PlaybackSpeed) => {
    if (get().playbackSpeed !== speed) {
      set({ playbackSpeed: speed });
    }
  },

  setError: (error: string) => {
    set({
      playbackState: "error",
      errorMessage: error,
    });
  },

  clearError: () => {
    const { errorMessage, playbackState } = get();
    if (errorMessage !== null || playbackState === "error") {
      set({
        errorMessage: null,
        playbackState: "stopped",
      });
    }
  },

  onPlaybackCompleted: () => {
    set({
      playbackState: "completed",
      currentPosition: 0,
    });
  },

  reset: () => {
    set({
      playbackState: "stopped",
      currentPosition: 0,
      totalDuration: 0,
      playbackSpeed: 1.0,
      errorMessage: null,
    });
  },

  setCurrentEpisode: (episode: Episode | null) => {
    set({ currentEpisode: episode });
  },
}));
