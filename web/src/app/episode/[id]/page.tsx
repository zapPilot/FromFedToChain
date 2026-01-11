"use client";

import { use, Suspense } from "react";
import Link from "next/link";
import ReactMarkdown from "react-markdown";
import { ArrowLeft, Play, Pause, Clock, Calendar, Share2 } from "lucide-react";

import { useEpisode, useEpisodes } from "@/hooks/use-episodes";
import { useAudioPlayer } from "@/hooks/use-audio-player";
import { useEpisodeContent } from "@/hooks/use-episode-content";
import {
  CATEGORY_COLORS,
  CATEGORY_EMOJIS,
  CATEGORY_NAMES,
} from "@/types/content";
import { formatDuration } from "@/lib/utils/format-duration";

// Helper to resolve params
function EpisodeContent({ id }: { id: string }) {
  // Ensure episodes are loaded
  const { isLoading, error } = useEpisodes(true);
  const episode = useEpisode(id);

  const { currentEpisode, isPlaying, play, pause } = useAudioPlayer();

  // Fetch full content (transcript, references) from API
  const {
    content: fetchedContent,
    references: fetchedReferences,
    isLoading: isContentLoading,
  } = useEpisodeContent(episode);

  const isCurrentEpisode = currentEpisode?.id === episode?.id;
  const isPlayingCurrent = isCurrentEpisode && isPlaying;

  const handlePlay = () => {
    if (!episode) return;
    if (isPlayingCurrent) {
      pause();
    } else {
      play(episode);
    }
  };

  if (isLoading && !episode) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-4">
        <div className="w-8 h-8 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin" />
        <p className="text-zinc-500">Loading episode content...</p>
      </div>
    );
  }

  if (error || (!isLoading && !episode)) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[60vh] space-y-6 text-center">
        <div className="p-4 rounded-full bg-red-500/10 text-red-500">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-8 w-8"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
            />
          </svg>
        </div>
        <div className="space-y-2">
          <h2 className="text-2xl font-bold text-white">Episode Not Found</h2>
          <p className="text-zinc-400 max-w-md">
            We couldn't find the episode you're looking for. It may have been
            removed or the URL is incorrect.
          </p>
        </div>
        <Link
          href="/"
          className="px-6 py-3 rounded-full bg-white text-black font-bold hover:bg-zinc-200 transition-colors"
        >
          Back to Feed
        </Link>
      </div>
    );
  }

  if (!episode) return null;

  return (
    <article className="max-w-3xl mx-auto px-6 py-12 md:py-20 pb-32">
      {/* Back Button */}
      <Link
        href="/"
        className="inline-flex items-center text-sm text-zinc-400 hover:text-white transition-colors mb-8 group"
      >
        <ArrowLeft className="w-4 h-4 mr-2 group-hover:-translate-x-1 transition-transform" />
        Back to Feed
      </Link>

      {/* Header */}
      <header className="mb-12 space-y-6">
        <div className="flex flex-wrap gap-3">
          <span
            className="px-3 py-1 rounded-full text-xs font-medium border"
            style={{
              borderColor: CATEGORY_COLORS[episode.category],
              color: CATEGORY_COLORS[episode.category],
              backgroundColor: `${CATEGORY_COLORS[episode.category]}15`,
            }}
          >
            {CATEGORY_EMOJIS[episode.category]}{" "}
            {CATEGORY_NAMES[episode.category]}
          </span>
          <span className="flex items-center px-3 py-1 rounded-full text-xs font-medium bg-white/5 text-zinc-400 border border-white/5">
            <Calendar className="w-3 h-3 mr-1.5" />
            {episode.date}
          </span>
          {episode.duration && (
            <span className="flex items-center px-3 py-1 rounded-full text-xs font-medium bg-white/5 text-zinc-400 border border-white/5">
              <Clock className="w-3 h-3 mr-1.5" />
              {formatDuration(episode.duration)}
            </span>
          )}
        </div>

        <h1 className="text-3xl md:text-5xl font-bold text-white leading-tight tracking-tight">
          {episode.title}
        </h1>

        {/* Play Action Bar */}
        <div className="flex items-center justify-between py-6 border-y border-white/10">
          <div className="flex items-center gap-4">
            <div className="relative group">
              <div
                className={`absolute -inset-1 rounded-full blur opacity-40 group-hover:opacity-75 transition-opacity duration-500`}
                style={{ backgroundColor: CATEGORY_COLORS[episode.category] }}
              />
              <button
                onClick={handlePlay}
                className="relative flex items-center justify-center w-14 h-14 rounded-full bg-white text-black hover:scale-105 transition-transform duration-300"
                aria-label={isPlayingCurrent ? "Pause" : "Play"}
              >
                {isPlayingCurrent ? (
                  <Pause className="w-6 h-6 fill-current" />
                ) : (
                  <Play className="w-6 h-6 fill-current ml-1" />
                )}
              </button>
            </div>
            <div>
              <div className="text-sm font-medium text-zinc-400 mb-0.5">
                Listen to episode
              </div>
              <div className="text-xs text-zinc-500">
                Audio • {formatDuration(episode.duration || 0)}
              </div>
            </div>
          </div>

          <button
            className="p-2 rounded-full text-zinc-400 hover:text-white hover:bg-white/10 transition-colors"
            title="Share"
            onClick={() => {
              navigator.clipboard.writeText(window.location.href);
              // Could add toast here
            }}
          >
            <Share2 className="w-5 h-5" />
          </button>
        </div>
      </header>

      {/* Content */}
      <div className="prose prose-invert prose-lg max-w-none prose-headings:font-bold prose-headings:text-white prose-p:text-zinc-300 prose-p:leading-relaxed prose-a:text-indigo-400 prose-a:no-underline hover:prose-a:underline prose-strong:text-white prose-li:text-zinc-300">
        {isContentLoading ? (
          <div className="flex items-center gap-3 py-8">
            <div className="w-5 h-5 border-2 border-indigo-500 border-t-transparent rounded-full animate-spin" />
            <span className="text-zinc-400">Loading transcript...</span>
          </div>
        ) : (
          <ReactMarkdown>
            {fetchedContent ||
              episode.content ||
              episode.description ||
              "_No transcript available for this episode._"}
          </ReactMarkdown>
        )}
      </div>

      {/* References */}
      {(() => {
        const references =
          fetchedReferences.length > 0
            ? fetchedReferences
            : episode.references || [];

        if (references.length === 0) return null;

        return (
          <div className="mt-16 pt-8 border-t border-white/10">
            <h3 className="text-sm font-bold text-zinc-500 uppercase tracking-wider mb-4">
              References
            </h3>
            <ul className="space-y-2">
              {references.map((ref, i) => (
                <li key={i} className="text-sm text-zinc-400">
                  {ref.startsWith("http") ? (
                    <a
                      href={ref}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="hover:text-white hover:underline truncate block"
                    >
                      {ref}
                    </a>
                  ) : (
                    <span>{ref}</span>
                  )}
                </li>
              ))}
            </ul>
          </div>
        );
      })()}
    </article>
  );
}

export default function EpisodePage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  // Unwrap params using React.use()
  const { id } = use(params);

  return (
    <Suspense fallback={<div className="min-h-screen bg-black" />}>
      <EpisodeContent id={id} />
    </Suspense>
  );
}
