"use client";

import { useAudioPlayer } from "@/hooks/use-audio-player";
import { PlaybackSpeedSelector } from "./PlaybackSpeedSelector";
import { CATEGORY_EMOJIS } from "@/types/content";

/**
 * Renders the appropriate icon for the play/pause button based on state
 */
function renderPlayPauseIcon(isLoading: boolean, isPlaying: boolean) {
  if (isLoading) {
    return (
      <svg
        className="w-5 h-5 animate-spin text-zinc-500"
        fill="none"
        viewBox="0 0 24 24"
      >
        <circle
          className="opacity-25"
          cx="12"
          cy="12"
          r="10"
          stroke="currentColor"
          strokeWidth="4"
        />
        <path
          className="opacity-75"
          fill="currentColor"
          d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
        />
      </svg>
    );
  }

  if (isPlaying) {
    return (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
        <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
      </svg>
    );
  }

  return (
    <svg className="w-5 h-5 ml-0.5" fill="currentColor" viewBox="0 0 24 24">
      <path d="M8 5v14l11-7z" />
    </svg>
  );
}

/**
 * Mini player component - Floating "Dynamic Island" style dock
 * Shows current episode with playback controls
 */
export function MiniPlayer() {
  const {
    currentEpisode,
    isPlaying,
    isLoading,
    totalDuration,
    progress,
    formattedCurrentPosition,
    formattedTotalDuration,
    play,
    pause,
    seek,
    skipBackward,
    skipForward,
  } = useAudioPlayer();

  // Don't show mini player if no episode loaded
  if (!currentEpisode) {
    return null;
  }

  const handleProgressBarClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const percentage = x / rect.width;
    const newPosition = percentage * totalDuration;
    seek(newPosition);
  };

  return (
    <div className="fixed bottom-6 left-4 right-4 md:left-1/2 md:right-auto md:-translate-x-1/2 md:w-full md:max-w-3xl z-50">
      <div className="bg-surface-1/90 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl overflow-hidden ring-1 ring-white/5">
        {/* Progress bar (Top Edge) */}
        <div
          className="h-1 bg-white/5 cursor-pointer group relative"
          onClick={handleProgressBarClick}
        >
          <div
            className="h-full bg-indigo-500 group-hover:bg-indigo-400 transition-all relative"
            style={{ width: `${progress * 100}%` }}
          >
            {/* Glow at the tip */}
            <div className="absolute right-0 top-1/2 -translate-y-1/2 w-2 h-2 bg-indigo-400 rounded-full shadow-[0_0_10px_currentColor] opacity-0 group-hover:opacity-100 transition-opacity" />
          </div>
          {/* Hover area helper */}
          <div className="absolute -top-2 -bottom-2 inset-x-0" />
        </div>

        <div className="px-5 py-4 flex items-center justify-between gap-4">
          {/* Track Info */}
          <div className="flex items-center gap-4 flex-1 min-w-0">
            <div className="w-10 h-10 rounded-lg bg-surface-3 flex items-center justify-center text-xl shadow-inner border border-white/5">
              {CATEGORY_EMOJIS[currentEpisode.category]}
            </div>
            <div className="min-w-0">
              <h4 className="text-sm font-semibold text-white truncate pr-2">
                {currentEpisode.title}
              </h4>
              <p className="text-xs text-zinc-400 truncate">
                {currentEpisode.category}
              </p>
            </div>
          </div>

          {/* Controls */}
          <div className="flex items-center gap-2 md:gap-4">
            {/* Time (Desktop only) */}
            <div className="hidden md:flex items-center gap-2 text-xs font-mono text-zinc-500 mr-2">
              <span className="text-zinc-300">{formattedCurrentPosition}</span>
              <span>/</span>
              <span>{formattedTotalDuration}</span>
            </div>

            <button
              onClick={() => skipBackward(15)}
              className="hidden sm:flex p-2 text-zinc-400 hover:text-white hover:bg-white/10 rounded-full transition-all"
              title="Rewind 15s"
            >
              <svg
                className="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12.066 11.2a1 1 0 000 1.6l5.334 4A1 1 0 0019 16V8a1 1 0 00-1.6-.8l-5.333 4zM4.066 11.2a1 1 0 000 1.6l5.334 4A1 1 0 0011 16V8a1 1 0 00-1.6-.8l-5.334 4z"
                />
              </svg>
            </button>

            <button
              onClick={() => (isPlaying ? pause() : play())}
              disabled={isLoading}
              className="w-12 h-12 flex items-center justify-center bg-white text-black hover:bg-zinc-200 rounded-full transition-all active:scale-95 shadow-[0_0_20px_rgba(255,255,255,0.2)]"
              aria-label={isPlaying ? "Pause" : "Play"}
            >
              {renderPlayPauseIcon(isLoading, isPlaying)}
            </button>

            <button
              onClick={() => skipForward(30)}
              className="hidden sm:flex p-2 text-zinc-400 hover:text-white hover:bg-white/10 rounded-full transition-all"
              title="Skip 30s"
            >
              <svg
                className="w-5 h-5"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M11.933 12.8a1 1 0 000-1.6L6.6 7.2A1 1 0 005 8v8a1 1 0 001.6.8l5.333-4zM19.933 12.8a1 1 0 000-1.6l-5.333-4A1 1 0 0013 8v8a1 1 0 001.6.8l5.333-4z"
                />
              </svg>
            </button>

            <div className="w-px h-8 bg-white/10 mx-2 hidden md:block" />

            <div className="hidden md:block">
              <PlaybackSpeedSelector />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
