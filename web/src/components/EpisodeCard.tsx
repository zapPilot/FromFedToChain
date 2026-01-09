import Link from "next/link";
import { Episode, CATEGORY_EMOJIS, CATEGORY_NAMES } from "@/types/content";

interface EpisodeCardProps {
  episode: Episode;
}

export default function EpisodeCard({ episode }: EpisodeCardProps) {
  const formattedDate = new Date(episode.date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  return (
    <Link href={`/episode/${episode.id}`} className="block group">
      <article className="bg-zinc-900 rounded-lg p-6 hover:bg-zinc-800 transition-colors border border-zinc-800">
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

        <div className="flex items-center gap-2 text-sm text-zinc-500">
          <span>Listen</span>
          <span className="group-hover:translate-x-1 transition-transform inline-block">
            →
          </span>
        </div>
      </article>
    </Link>
  );
}
