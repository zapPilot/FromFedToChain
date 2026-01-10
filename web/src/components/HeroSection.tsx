"use client";
import Link from "next/link";
import { Episode, CATEGORY_NAMES } from "@/types/content";
import { useAudioPlayer } from "@/hooks/use-audio-player";
import { formatDurationWithUnits } from "@/lib/utils/format-duration";

interface HeroSectionProps {
  episode?: Episode;
  isLoading?: boolean;
}

export function HeroSection({ episode, isLoading }: HeroSectionProps) {
  const { play, pause, isPlaying, currentEpisode } = useAudioPlayer();

  if (isLoading) {
    return (
      <div className="w-full h-64 rounded-2xl bg-zinc-900/50 animate-pulse mb-8 border border-white/5" />
    );
  }

  if (!episode) return null;

  const isCurrent = currentEpisode?.id === episode.id;
  const isPlayingCurrent = isCurrent && isPlaying;

  return (
    <section className="relative w-full overflow-hidden rounded-3xl border border-white/10 mb-10 group bg-surface-1">
      {/* Background Gradient / Abstract Art */}
      <div className="absolute inset-0 bg-gradient-to-br from-indigo-900/40 via-purple-900/20 to-black z-0" />

      {/* Glow Effect */}
      <div className="absolute -top-24 -right-24 w-96 h-96 bg-accent-primary/20 rounded-full blur-3xl" />

      <div className="relative z-10 p-8 md:p-10 flex flex-col md:flex-row gap-8 items-start md:items-center justify-between">
        <div className="flex-1 space-y-4">
          <div className="flex items-center gap-3">
            <span className="px-3 py-1 rounded-full text-xs font-medium bg-white/10 text-white border border-white/10 backdrop-blur-md">
              Featured • {CATEGORY_NAMES[episode.category]}
            </span>
            <span className="text-zinc-400 text-xs uppercase tracking-wider">
              {new Date(episode.date).toLocaleDateString(undefined, {
                weekday: "long",
                month: "long",
                day: "numeric",
              })}
            </span>
          </div>

          <Link href={`/episode/${episode.id}`} className="block group/title">
            <h1 className="text-3xl md:text-5xl font-bold text-white tracking-tight leading-tight max-w-2xl group-hover/title:text-indigo-400 group-hover/title:underline transition-colors">
              {episode.title}
            </h1>
          </Link>

          <p className="text-zinc-300 text-base md:text-lg max-w-xl line-clamp-2 leading-relaxed">
            {episode.description ||
              "Listen to the latest market intelligence and analysis."}
          </p>

          <div className="pt-2 flex items-center gap-4">
            <button
              onClick={() => (isPlayingCurrent ? pause() : play(episode))}
              className="flex items-center gap-3 px-8 py-4 bg-white text-black hover:bg-zinc-200 rounded-full font-bold transition-transform active:scale-95 shadow-[0_0_20px_rgba(255,255,255,0.3)]"
            >
              {isPlayingCurrent ? (
                <>
                  <svg
                    className="w-5 h-5"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path d="M6 4h4v16H6V4zm8 0h4v16h-4V4z" />
                  </svg>
                  Pause Briefing
                </>
              ) : (
                <>
                  <svg
                    className="w-5 h-5"
                    fill="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path d="M8 5v14l11-7z" />
                  </svg>
                  Play Briefing
                </>
              )}
            </button>

            {episode.duration && (
              <span className="text-zinc-400 font-mono text-sm">
                {formatDurationWithUnits(episode.duration)}
              </span>
            )}
          </div>
        </div>

        {/* Visual Decoration (Right side) - Abstract Waveform representation */}
        <div className="hidden md:flex items-center justify-center w-32 h-32 rounded-full border border-white/10 bg-white/5 backdrop-blur-md">
          <div className="flex items-end gap-1 h-12">
            {[...Array(5)].map((_, i) => (
              <div
                key={i}
                className={`w-1 bg-white/50 rounded-full ${isPlayingCurrent ? "animate-pulse" : ""}`}
                style={{
                  height: `${Math.max(20, Math.random() * 100)}%`,
                  animationDelay: `${i * 0.1}s`,
                }}
              />
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
