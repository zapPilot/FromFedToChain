import { useProgressStore } from "@/stores/progress-store";
import type { EpisodeProgress } from "@/stores/progress-store";

/**
 * Hook for episode progress tracking
 * Abstracts progress store interactions
 *
 * @param episodeId - Optional episode ID to get progress for
 * @returns Progress data and control functions
 */
export function useProgress(episodeId?: string) {
  const store = useProgressStore();

  // Get progress for specific episode if ID provided
  const episodeProgress = episodeId ? store.getProgress(episodeId) : null;

  return {
    // Episode-specific progress (if episodeId provided)
    progress: episodeProgress,
    resumePosition: episodeId ? store.getResumePosition(episodeId) : 0,

    // Global progress data
    allProgress: store.progress,

    // Actions
    updateProgress: store.updateProgress,
    getProgress: store.getProgress,
    getResumePosition: store.getResumePosition,
    markCompleted: store.markCompleted,
    clearProgress: store.clearProgress,
    clearAllProgress: store.clearAllProgress,

    // Lists
    recentEpisodes: store.getRecentEpisodes,
    unfinishedEpisodes: store.getUnfinishedEpisodes,
  };
}

/**
 * Hook for getting progress data for multiple episodes
 *
 * @param episodeIds - Array of episode IDs
 * @returns Map of episode ID to progress data
 */
export function useMultipleProgress(episodeIds: string[]) {
  const store = useProgressStore();

  const progressMap: Record<string, EpisodeProgress | null> = {};

  for (const id of episodeIds) {
    progressMap[id] = store.getProgress(id);
  }

  return {
    progressMap,
    getProgress: store.getProgress,
  };
}
