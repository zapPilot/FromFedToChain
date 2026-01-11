"use client";

import { useAudioPlayer } from "@/hooks/use-audio-player";
import { PlaybackSpeedSelector } from "./PlaybackSpeedSelector";
import { CATEGORY_EMOJIS } from "@/types/content";

import { FastForward, Loader2, Pause, Play, Rewind } from "lucide-react";

interface ProgressBarProps {
  progress: number;
  totalDuration: number;
  onSeek: (position: number) => void;
}

function ProgressBar({ progress, totalDuration, onSeek }: ProgressBarProps) {
  const handleClick = (e: React.MouseEvent<HTMLDivElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const percentage = x / rect.width;
    const newPosition = percentage * totalDuration;
    onSeek(newPosition);
  };

  return (
    <div
      className="h-1 bg-white/5 cursor-pointer group relative"
      onClick={handleClick}
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

  return (
    <div className="fixed bottom-6 left-4 right-4 md:left-1/2 md:right-auto md:-translate-x-1/2 md:w-full md:max-w-3xl z-50">
      <div className="bg-surface-1/90 backdrop-blur-xl border border-white/10 rounded-2xl shadow-2xl overflow-hidden ring-1 ring-white/5">
        {/* Progress bar (Top Edge) */}
        <ProgressBar
          progress={progress}
          totalDuration={totalDuration}
          onSeek={seek}
        />

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
              <Rewind className="w-5 h-5" />
            </button>

            <button
              onClick={() => (isPlaying ? pause() : play())}
              disabled={isLoading}
              className="w-12 h-12 flex items-center justify-center bg-white text-black hover:bg-zinc-200 rounded-full transition-all active:scale-95 shadow-[0_0_20px_rgba(255,255,255,0.2)]"
              aria-label={isPlaying ? "Pause" : "Play"}
            >
              {isLoading ? (
                <Loader2 className="w-5 h-5 animate-spin text-zinc-500" />
              ) : isPlaying ? (
                <Pause className="w-5 h-5 fill-current" />
              ) : (
                <Play className="w-5 h-5 fill-current ml-0.5" />
              )}
            </button>

            <button
              onClick={() => skipForward(30)}
              className="hidden sm:flex p-2 text-zinc-400 hover:text-white hover:bg-white/10 rounded-full transition-all"
              title="Skip 30s"
            >
              <FastForward className="w-5 h-5" />
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
