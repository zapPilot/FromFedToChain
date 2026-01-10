"use client";

import {
  Episode,
  CATEGORY_EMOJIS,
  CATEGORY_NAMES,
  Category,
} from "@/types/content";
import { useAudioPlayer } from "@/hooks/use-audio-player";
import { useProgress } from "@/hooks/use-progress";
import { formatDurationWithUnits } from "@/lib/utils/format-duration";

interface EpisodeCardProps {
  episode: Episode;
}

const CATEGORY_COLORS: Record<Category, string> = {
  "daily-news": "var(--accent-news)",
  ethereum: "var(--accent-ethereum)",
  macro: "var(--accent-macro)",
  startup: "var(--accent-startup)",
  ai: "var(--accent-ai)",
  defi: "var(--accent-defi)",
};

export function EpisodeCard({ episode }: EpisodeCardProps) {
  const { currentEpisode, isPlaying, play, pause } = useAudioPlayer();
  const { progress } = useProgress(episode.id);

  const formattedDate = new Date(episode.date).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });

  const isCurrentEpisode = currentEpisode?.id === episode.id;
  const isCurrentlyPlaying = isCurrentEpisode && isPlaying;
  const progressPercent = progress ? progress.progress * 100 : 0;

  const accentColor =
    CATEGORY_COLORS[episode.category] || "var(--accent-primary)";

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
      className="group relative flex flex-col h-full rounded-2xl border border-white/5 bg-surface-1/50 backdrop-blur-sm transition-all duration-300 hover:bg-surface-2 hover:-translate-y-1 hover:shadow-xl overflow-hidden"
      onClick={handlePlayPause}
      style={
        {
          // subtle glow on hover based on category
          "--hover-shadow": `0 10px 40px -10px ${accentColor}33`,
        } as React.CSSProperties
      }
    >
      {/* Hover Glow Effect */}
      <div
        className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none z-0"
        style={{
          boxShadow: "inset 0 0 80px -20px var(--hover-shadow, transparent)",
        }}
      />

      <div className="relative z-10 flex flex-col flex-1 p-5">
        {/* Top Row: Category & Date */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <span
              className="flex items-center justify-center w-8 h-8 rounded-full bg-white/5 border border-white/5 text-lg"
              style={{ color: accentColor }}
            >
              {CATEGORY_EMOJIS[episode.category]}
            </span>
            <span className="text-xs font-medium text-zinc-400 uppercase tracking-widest">
              {CATEGORY_NAMES[episode.category]}
            </span>
          </div>
          <time className="text-xs font-mono text-zinc-500">
            {formattedDate}
          </time>
        </div>

        {/* Title */}
        <h3 className="text-lg font-bold text-white mb-2 line-clamp-2 leading-tight group-hover:text-transparent group-hover:bg-clip-text group-hover:bg-gradient-to-r group-hover:from-white group-hover:to-zinc-400 transition-all">
          {episode.title}
        </h3>

        {/* Description */}
        <p className="text-sm text-zinc-400 line-clamp-3 mb-4 flex-1">
          {episode.description}
        </p>

        {/* Footer: Tech info / Duration */}
        <div className="flex items-center justify-between mt-auto pt-4 border-t border-white/5">
          <span className="text-xs font-mono text-zinc-500 flex items-center gap-1">
            {episode.duration && (
              <>
                <svg
                  className="w-3 h-3"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    strokeWidth={2}
                    d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                {formatDurationWithUnits(episode.duration)}
              </>
            )}
          </span>

          <button
            className={`
              w-10 h-10 rounded-full flex items-center justify-center transition-all duration-300
              ${
                isCurrentlyPlaying
                  ? "bg-white text-black scale-110 shadow-[0_0_15px_rgba(255,255,255,0.4)]"
                  : "bg-white/10 text-white hover:bg-white hover:text-black group-hover:scale-110"
              }
            `}
          >
            {isCurrentlyPlaying ? (
              <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
                <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
              </svg>
            ) : (
              <svg
                className="w-4 h-4 ml-0.5"
                fill="currentColor"
                viewBox="0 0 24 24"
              >
                <path d="M8 5v14l11-7z" />
              </svg>
            )}
          </button>
        </div>
      </div>

      {/* Progress Bar overlay at bottom */}
      {progress && progressPercent > 0 && (
        <div className="absolute bottom-0 left-0 right-0 h-1 bg-white/10">
          <div
            className="h-full transition-all duration-300"
            style={{
              width: `${progressPercent}%`,
              backgroundColor: accentColor,
            }}
          />
        </div>
      )}
    </article>
  );
}

export default EpisodeCard;
