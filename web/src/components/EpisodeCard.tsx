"use client";

import { Play, Pause } from "lucide-react";

import Link from "next/link";
import {
  Episode,
  CATEGORY_EMOJIS,
  CATEGORY_NAMES,
  CATEGORY_COLORS,
  Category,
} from "@/types/content";
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

      <div className="flex flex-1 items-start gap-4 p-5">
        {/* Play Button */}
        <button
          onClick={handlePlayPause}
          className={`
            flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center transition-all duration-300 group-hover:scale-105
            ${isCurrentlyPlaying
              ? "bg-white text-black shadow-[0_0_15px_rgba(255,255,255,0.3)]"
              : "bg-white/10 text-white hover:bg-white hover:text-black"
            }
          `}
          aria-label={isCurrentlyPlaying ? "Pause" : "Play"}
        >
          {isCurrentlyPlaying ? (
            <Pause className="w-5 h-5 fill-current" />
          ) : (
            <Play className="w-5 h-5 fill-current ml-1" />
          )}
        </button>

        {/* Content - Clickable Link */}
        <Link
          href={`/episode/${episode.id}`}
          className="flex-1 min-w-0 group/link"
        >
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
          <h3 className="text-lg font-bold text-white mb-2 line-clamp-2 leading-tight group-hover/link:text-indigo-400 group-hover/link:underline transition-all">
            {episode.title}
          </h3>

          {/* Description */}
          <p className="text-sm text-zinc-400 line-clamp-2 mb-3 flex-1">
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

            {/* View Details Arrow */}
            <span className="text-xs font-medium text-indigo-400 opacity-0 group-hover/link:opacity-100 transition-opacity flex items-center gap-1">
              Read Script →
            </span>
          </div>
        </Link>
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
