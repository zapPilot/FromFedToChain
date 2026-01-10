"use client";

import { useEpisodes } from "@/hooks/use-episodes";
import { FilterBar } from "@/components/FilterBar";
import { EpisodeList } from "@/components/EpisodeList";
import { MiniPlayer } from "@/components/MiniPlayer";

export default function Home() {
  const {
    filteredEpisodes,
    isLoading,
    error,
    refreshEpisodes,
    episodeCount,
    hasFilters,
  } = useEpisodes(true); // Auto-load episodes on mount

  return (
    <>
      <div className="container mx-auto px-4 py-8 pb-32">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-4">Latest Episodes</h1>
          <p className="text-zinc-400 text-lg">
            Stay updated with the latest insights on crypto, macro economics,
            and blockchain technology.
          </p>
        </div>

        {/* Filters */}
        <div className="mb-8">
          <FilterBar />
        </div>

        {/* Results count */}
        {!isLoading && !error && (
          <div className="mb-4">
            <p className="text-sm text-zinc-500">
              {hasFilters ? (
                <>
                  Showing{" "}
                  <span className="font-medium text-zinc-400">
                    {episodeCount}
                  </span>{" "}
                  filtered
                  {episodeCount === 1 ? " episode" : " episodes"}
                </>
              ) : (
                <>
                  <span className="font-medium text-zinc-400">
                    {episodeCount}
                  </span>{" "}
                  total
                  {episodeCount === 1 ? " episode" : " episodes"}
                </>
              )}
            </p>
          </div>
        )}

        {/* Episode List */}
        <EpisodeList
          episodes={filteredEpisodes}
          isLoading={isLoading}
          error={error}
          onRetry={refreshEpisodes}
        />
      </div>

      {/* Mini Player (sticky bottom) */}
      <MiniPlayer />
    </>
  );
}
