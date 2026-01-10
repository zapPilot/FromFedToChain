import { useEffect } from "react";
import { useAudioPlayerStore } from "@/stores/audio-player-store";
import { getAudioPlayerManager } from "@/lib/audio/audio-player-manager";
import type { Episode } from "@/types/content";

/**
 * Hook for audio player controls
 * Abstracts audio player store and manager interactions
 *
 * @returns Audio player state and control functions
 */
export function useAudioPlayer() {
  const store = useAudioPlayerStore();

  // Connect store actions to audio manager on mount (browser only)
  useEffect(() => {
    // Get audio manager instance (only works in browser)
    const audioPlayerManager = getAudioPlayerManager();

    // Override store actions to use audio manager
    useAudioPlayerStore.setState({
      play: async (episode?: Episode) => {
        if (episode) {
          await audioPlayerManager.play(episode);
        } else {
          await audioPlayerManager.play();
        }
      },
      pause: () => {
        audioPlayerManager.pause();
      },
      seek: (position: number) => {
        audioPlayerManager.seek(position);
      },
      setSpeed: (speed) => {
        audioPlayerManager.setSpeed(speed);
      },
      skipForward: (seconds = 30) => {
        audioPlayerManager.skipForward(seconds);
      },
      skipBackward: (seconds = 15) => {
        audioPlayerManager.skipBackward(seconds);
      },
      stop: () => {
        audioPlayerManager.stop();
      },
    });
  }, []);

  return {
    // State
    currentEpisode: store.currentEpisode,
    playbackState: store.playbackState,
    currentPosition: store.currentPosition,
    totalDuration: store.totalDuration,
    playbackSpeed: store.playbackSpeed,
    errorMessage: store.errorMessage,

    // Computed
    isPlaying: store.isPlaying(),
    isPaused: store.isPaused(),
    isLoading: store.isLoading(),
    hasError: store.hasError(),
    isIdle: store.isIdle(),
    isCompleted: store.isCompleted(),
    progress: store.progress(),
    formattedCurrentPosition: store.formattedCurrentPosition(),
    formattedTotalDuration: store.formattedTotalDuration(),

    // Actions
    play: store.play,
    pause: store.pause,
    seek: store.seek,
    setSpeed: store.setSpeed,
    skipForward: store.skipForward,
    skipBackward: store.skipBackward,
    stop: store.stop,
  };
}
