import { create } from "zustand";
import { persist } from "zustand/middleware";
import * as storage from "@/lib/utils/storage";

/**
 * Progress data for a single episode
 */
export interface EpisodeProgress {
  position: number; // Current position in seconds
  duration: number; // Total duration in seconds
  progress: number; // Progress as decimal (0-1)
  lastPlayed: string; // ISO timestamp
  completed: boolean; // Mark as completed if >95%
}

/**
 * Progress store state
 */
interface ProgressState {
  // Progress data indexed by episode ID
  progress: Record<string, EpisodeProgress>;

  // Actions
  updateProgress: (
    episodeId: string,
    position: number,
    duration: number,
  ) => void;
  getProgress: (episodeId: string) => EpisodeProgress | null;
  getResumePosition: (episodeId: string) => number;
  markCompleted: (episodeId: string) => void;
  clearProgress: (episodeId: string) => void;
  clearAllProgress: () => void;
  getRecentEpisodes: (limit?: number) => string[];
  getUnfinishedEpisodes: () => string[];
}

/**
 * Completion threshold (95%)
 */
const COMPLETION_THRESHOLD = 0.95;

/**
 * Resume range (5% - 95%)
 * If progress < 5% or > 95%, start from beginning
 */
const RESUME_MIN = 0.05;
const RESUME_MAX = 0.95;

/**
 * Progress tracking store with localStorage persistence
 *
 * Implements Flutter's AudioProgressTracker logic:
 * - Updates throttled at 1000ms (handled by audio player)
 * - Marks >95% as completed, resets to 0
 * - Resume position: 5%-95% range, else start from 0
 */
export const useProgressStore = create<ProgressState>()(
  persist(
    (set, get) => ({
      progress: {},

      /**
       * Update episode progress
       * Automatically marks as completed if >95%
       */
      updateProgress: (episodeId, position, duration) => {
        if (!episodeId || !isFinite(position) || !isFinite(duration)) {
          return;
        }

        const progress = duration > 0 ? position / duration : 0;
        const completed = progress >= COMPLETION_THRESHOLD;

        set((state) => ({
          progress: {
            ...state.progress,
            [episodeId]: {
              position: completed ? 0 : position, // Reset to 0 if completed
              duration,
              progress: completed ? 1 : progress,
              lastPlayed: new Date().toISOString(),
              completed,
            },
          },
        }));
      },

      /**
       * Get progress for an episode
       */
      getProgress: (episodeId) => {
        const state = get();
        return state.progress[episodeId] ?? null;
      },

      /**
       * Get resume position for an episode
       * Returns 0 if:
       * - No progress recorded
       * - Progress < 5% (barely started)
       * - Progress > 95% (already completed)
       * Otherwise returns saved position
       */
      getResumePosition: (episodeId) => {
        const state = get();
        const episodeProgress = state.progress[episodeId];

        if (!episodeProgress) {
          return 0;
        }

        const { progress, position, completed } = episodeProgress;

        // If completed or outside resume range, start from beginning
        if (completed || progress < RESUME_MIN || progress > RESUME_MAX) {
          return 0;
        }

        return position;
      },

      /**
       * Mark episode as completed
       */
      markCompleted: (episodeId) => {
        set((state) => {
          const existing = state.progress[episodeId];
          if (!existing) return state;

          return {
            progress: {
              ...state.progress,
              [episodeId]: {
                ...existing,
                position: 0,
                progress: 1,
                completed: true,
                lastPlayed: new Date().toISOString(),
              },
            },
          };
        });
      },

      /**
       * Clear progress for a specific episode
       */
      clearProgress: (episodeId) => {
        set((state) => {
          const { [episodeId]: _, ...remaining } = state.progress;
          return { progress: remaining };
        });
      },

      /**
       * Clear all progress
       */
      clearAllProgress: () => {
        set({ progress: {} });
      },

      /**
       * Get recent episodes sorted by last played
       */
      getRecentEpisodes: (limit = 20) => {
        const state = get();
        const entries = Object.entries(state.progress);

        return entries
          .sort((a, b) => {
            const timeA = new Date(a[1].lastPlayed).getTime();
            const timeB = new Date(b[1].lastPlayed).getTime();
            return timeB - timeA; // Newest first
          })
          .slice(0, limit)
          .map(([id]) => id);
      },

      /**
       * Get unfinished episodes (5%-95% progress)
       */
      getUnfinishedEpisodes: () => {
        const state = get();
        const entries = Object.entries(state.progress);

        return entries
          .filter(([_, data]) => {
            const { progress, completed } = data;
            return (
              !completed && progress >= RESUME_MIN && progress <= RESUME_MAX
            );
          })
          .sort((a, b) => {
            const timeA = new Date(a[1].lastPlayed).getTime();
            const timeB = new Date(b[1].lastPlayed).getTime();
            return timeB - timeA; // Newest first
          })
          .map(([id]) => id);
      },
    }),
    {
      name: "episode-progress", // localStorage key
      storage: {
        getItem: (name) => {
          const value = storage.getItem(name);
          return value ? JSON.parse(value) : null;
        },
        setItem: (name, value) => {
          storage.setItem(name, JSON.stringify(value));
        },
        removeItem: (name) => {
          storage.removeItem(name);
        },
      },
    },
  ),
);
