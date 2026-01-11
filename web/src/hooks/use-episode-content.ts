import { useState, useEffect } from "react";
import type { Episode } from "@/types/content";
import { StreamingApiService } from "@/lib/api/streaming-api";

/**
 * Hook for fetching full episode content (transcript, references)
 *
 * The episode list API only returns basic metadata. This hook fetches
 * the full content from /api/content/{lang}/{category}/{id} when needed.
 *
 * @param episode - Episode to fetch content for (can be null)
 * @returns Content state with loading/error handling
 */
export function useEpisodeContent(episode: Episode | null) {
  const [content, setContent] = useState<string | null>(null);
  const [references, setReferences] = useState<string[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Skip if no episode
    if (!episode) {
      setContent(null);
      setReferences([]);
      setIsLoading(false);
      setError(null);
      return;
    }

    // If episode already has content, use it directly
    if (episode.content && episode.content.trim().length > 0) {
      setContent(episode.content);
      setReferences(episode.references || []);
      setIsLoading(false);
      setError(null);
      return;
    }

    // Capture episode values for the fetch
    const { language, category, id } = episode;

    // Fetch content from API
    let cancelled = false;

    async function fetchContent() {
      setIsLoading(true);
      setError(null);

      try {
        const contentData = await StreamingApiService.fetchEpisodeContent(
          language,
          category,
          id,
        );

        if (cancelled) return;

        if (contentData) {
          setContent(contentData.content || contentData.description || null);
          setReferences(contentData.references || []);
        } else {
          setContent(null);
          setReferences([]);
          setError("Content not available for this episode.");
        }
      } catch (err) {
        if (cancelled) return;
        const errorMessage =
          err instanceof Error ? err.message : "Failed to load content";
        setError(errorMessage);
        console.error("Error fetching episode content:", err);
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    }

    fetchContent();

    return () => {
      cancelled = true;
    };
  }, [episode?.id, episode?.language, episode?.category, episode?.content]);

  return {
    /** Transcript/content text (markdown format) */
    content,
    /** List of reference URLs/sources */
    references,
    /** Whether content is currently being fetched */
    isLoading,
    /** Error message if fetch failed */
    error,
    /** Whether content is available */
    hasContent: content !== null && content.trim().length > 0,
  };
}
