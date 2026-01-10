import { Episode, CATEGORY_EMOJIS, CATEGORY_NAMES } from "@/types/content";
import { useAudioPlayer } from "@/hooks/use-audio-player";
import { useProgress } from "@/hooks/use-progress";
import { formatDurationWithUnits } from "@/lib/utils/format-duration";

interface EpisodeCardProps {
  episode: Episode;
}

export function EpisodeCard({ episode }: EpisodeCardProps) {
  const { currentEpisode, isPlaying, play, pause } = useAudioPlayer();
  const { progress } = useProgress(episode.id);

  const formattedDate = new Date(episode.date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  const isCurrentEpisode = currentEpisode?.id === episode.id;
  const isCurrentlyPlaying = isCurrentEpisode && isPlaying;
  const progressPercent = progress ? progress.progress * 100 : 0;

  const handlePlayPause = (e: React.MouseEvent) => {
    e.preventDefault();
    e.stopPropagation();

    if (isCurrentEpisode && isPlaying) {
      pause();
    } else {
      play(episode);
    }
  };

  return (
    <article
      className={`
        relative bg-zinc-900 rounded-lg overflow-hidden
        hover:bg-zinc-800 transition-all cursor-pointer
        border-2 ${isCurrentlyPlaying ? "border-zinc-600" : "border-zinc-800"}
        group
      `}
      onClick={handlePlayPause}
    >
      {/* Card content */}
      <div className="p-6">
        <div className="flex items-start justify-between gap-4 mb-3">
          <div className="flex items-center gap-2">
            <span className="text-2xl">
              {CATEGORY_EMOJIS[episode.category]}
            </span>
            <span className="text-sm text-zinc-400">
              {CATEGORY_NAMES[episode.category]}
            </span>
          </div>
          <time className="text-sm text-zinc-500">{formattedDate}</time>
        </div>

        <h2 className="text-xl font-semibold text-white mb-2 group-hover:text-zinc-200 transition-colors">
          {episode.title}
        </h2>

        {episode.description && (
          <p className="text-zinc-400 text-sm line-clamp-2 mb-4">
            {episode.description}
          </p>
        )}

        {/* Play button and duration */}
        <div className="flex items-center justify-between">
          <button
            onClick={handlePlayPause}
            className="flex items-center gap-2 px-4 py-2 bg-zinc-800 hover:bg-zinc-700 rounded-lg transition-colors"
          >
            {isCurrentlyPlaying ? (
              <>
                <svg
                  className="w-4 h-4 text-zinc-100"
                  fill="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
                </svg>
                <span className="text-sm text-zinc-300">Pause</span>
              </>
            ) : (
              <>
                <svg
                  className="w-4 h-4 text-zinc-100 ml-0.5"
                  fill="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path d="M8 5v14l11-7z" />
                </svg>
                <span className="text-sm text-zinc-300">Play</span>
              </>
            )}
          </button>

          {episode.duration && (
            <span className="text-xs text-zinc-500">
              {formatDurationWithUnits(episode.duration)}
            </span>
          )}
        </div>
      </div>

      {/* Progress bar at bottom */}
      {progress && progressPercent > 0 && (
        <div className="h-1 bg-zinc-800">
          <div
            className="h-full bg-zinc-500 transition-all"
            style={{ width: `${progressPercent}%` }}
          />
        </div>
      )}

      {/* Currently playing indicator */}
      {isCurrentlyPlaying && (
        <div className="absolute top-4 right-4">
          <div className="flex items-center gap-1.5 px-2 py-1 bg-zinc-700 rounded-full">
            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
            <span className="text-xs text-zinc-300 font-medium">Playing</span>
          </div>
        </div>
      )}
    </article>
  );
}

export default EpisodeCard;
