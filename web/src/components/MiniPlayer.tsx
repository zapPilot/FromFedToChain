import { useAudioPlayer } from "@/hooks/use-audio-player";
import { PlaybackSpeedSelector } from "./PlaybackSpeedSelector";
import { CATEGORY_EMOJIS } from "@/types/content";

/**
 * Mini player component - sticky bottom audio player
 * Shows current episode with playback controls
 * Only visible when an episode is loaded
 */
export function MiniPlayer() {
  const {
    currentEpisode,
    isPlaying,
    isPaused,
    isLoading,
    currentPosition,
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
    <div className="fixed bottom-0 left-0 right-0 bg-zinc-900 border-t border-zinc-800 shadow-2xl z-50">
      {/* Progress bar */}
      <div
        className="h-1 bg-zinc-800 cursor-pointer group"
        onClick={handleProgressBarClick}
      >
        <div
          className="h-full bg-zinc-400 group-hover:bg-zinc-300 transition-all relative"
          style={{ width: `${progress * 100}%` }}
        >
          {/* Progress handle */}
          <div className="absolute right-0 top-1/2 -translate-y-1/2 w-3 h-3 bg-zinc-100 rounded-full opacity-0 group-hover:opacity-100 transition-opacity shadow-lg" />
        </div>
      </div>

      {/* Player controls */}
      <div className="container mx-auto px-4 py-3">
        <div className="flex items-center gap-4">
          {/* Episode info */}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <span className="text-lg">
                {CATEGORY_EMOJIS[currentEpisode.category]}
              </span>
              <div className="min-w-0 flex-1">
                <h4 className="text-sm font-medium text-zinc-100 truncate">
                  {currentEpisode.title}
                </h4>
                <p className="text-xs text-zinc-500 truncate">
                  {currentEpisode.category} • {currentEpisode.language}
                </p>
              </div>
            </div>
          </div>

          {/* Playback controls */}
          <div className="flex items-center gap-3">
            {/* Skip backward 15s */}
            <button
              onClick={() => skipBackward(15)}
              className="p-2 hover:bg-zinc-800 rounded-lg transition-colors"
              aria-label="Skip backward 15 seconds"
              title="Skip backward 15s"
            >
              <svg
                className="w-5 h-5 text-zinc-300"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M12.066 11.2a1 1 0 000 1.6l5.334 4A1 1 0 0019 16V8a1 1 0 00-1.6-.8l-5.333 4zM4.066 11.2a1 1 0 000 1.6l5.334 4A1 1 0 0011 16V8a1 1 0 00-1.6-.8l-5.334 4z"
                />
              </svg>
            </button>

            {/* Play/Pause button */}
            <button
              onClick={() => (isPlaying ? pause() : play())}
              disabled={isLoading}
              className="p-3 bg-zinc-700 hover:bg-zinc-600 rounded-full transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              aria-label={isPlaying ? "Pause" : "Play"}
            >
              {isLoading ? (
                <svg
                  className="w-6 h-6 text-zinc-100 animate-spin"
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
              ) : isPlaying ? (
                <svg
                  className="w-6 h-6 text-zinc-100"
                  fill="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
                </svg>
              ) : (
                <svg
                  className="w-6 h-6 text-zinc-100 ml-0.5"
                  fill="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path d="M8 5v14l11-7z" />
                </svg>
              )}
            </button>

            {/* Skip forward 30s */}
            <button
              onClick={() => skipForward(30)}
              className="p-2 hover:bg-zinc-800 rounded-lg transition-colors"
              aria-label="Skip forward 30 seconds"
              title="Skip forward 30s"
            >
              <svg
                className="w-5 h-5 text-zinc-300"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M11.933 12.8a1 1 0 000-1.6L6.6 7.2A1 1 0 005 8v8a1 1 0 001.6.8l5.333-4zM19.933 12.8a1 1 0 000-1.6l-5.333-4A1 1 0 0013 8v8a1 1 0 001.6.8l5.333-4z"
                />
              </svg>
            </button>
          </div>

          {/* Time display */}
          <div className="hidden sm:flex items-center gap-2 text-xs text-zinc-400 font-mono">
            <span>{formattedCurrentPosition}</span>
            <span>/</span>
            <span>{formattedTotalDuration}</span>
          </div>

          {/* Playback speed selector */}
          <div className="hidden md:block">
            <PlaybackSpeedSelector />
          </div>
        </div>
      </div>
    </div>
  );
}
