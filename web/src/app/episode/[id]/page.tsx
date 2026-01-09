import { notFound } from "next/navigation";
import Link from "next/link";
import { getEpisodeById } from "@/data/mock-content";
import { CATEGORY_EMOJIS, CATEGORY_NAMES } from "@/types/content";
import AudioPlayer from "@/components/AudioPlayer";

interface EpisodePageProps {
  params: Promise<{ id: string }>;
}

export default async function EpisodePage({ params }: EpisodePageProps) {
  const { id } = await params;
  const episode = getEpisodeById(id);

  if (!episode) {
    notFound();
  }

  const formattedDate = new Date(episode.date).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
  });

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-3xl mx-auto">
        <Link
          href="/"
          className="inline-flex items-center gap-2 text-zinc-400 hover:text-white transition-colors mb-6"
        >
          <svg
            className="w-5 h-5"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M15 19l-7-7 7-7"
            />
          </svg>
          Back to Episodes
        </Link>

        <article>
          <div className="flex items-center gap-2 mb-4">
            <span className="text-2xl">
              {CATEGORY_EMOJIS[episode.category]}
            </span>
            <span className="text-sm text-zinc-400">
              {CATEGORY_NAMES[episode.category]}
            </span>
            <span className="text-zinc-600">•</span>
            <time className="text-sm text-zinc-400">{formattedDate}</time>
          </div>

          <h1 className="text-4xl font-bold mb-6">{episode.title}</h1>

          {episode.description && (
            <p className="text-xl text-zinc-300 mb-8 leading-relaxed">
              {episode.description}
            </p>
          )}

          <div className="mb-8">
            <AudioPlayer episode={episode} />
          </div>

          <div
            className="prose prose-invert prose-lg max-w-none
              prose-headings:text-white
              prose-p:text-zinc-300
              prose-ul:text-zinc-300
              prose-li:text-zinc-300
              prose-strong:text-white
              prose-a:text-white prose-a:underline hover:prose-a:text-zinc-300"
            dangerouslySetInnerHTML={{ __html: episode.content }}
          />

          {episode.references && episode.references.length > 0 && (
            <div className="mt-12 pt-8 border-t border-zinc-800">
              <h2 className="text-2xl font-semibold mb-4">References</h2>
              <ul className="space-y-2">
                {episode.references.map((reference, index) => (
                  <li key={index} className="text-zinc-400">
                    {reference}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </article>
      </div>
    </div>
  );
}
