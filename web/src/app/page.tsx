"use client";

import { useEpisodes } from "@/hooks/use-episodes";
import { FilterBar } from "@/components/FilterBar";
import { EpisodeList } from "@/components/EpisodeList";
import { MiniPlayer } from "@/components/MiniPlayer";
import { HeroSection } from "@/components/HeroSection";

export default function Home() {
  const { filteredEpisodes, isLoading, error, refreshEpisodes, hasFilters } =
    useEpisodes(true); // Auto-load episodes on mount

  // Feature the first episode as the Hero
  const featuredEpisode = filteredEpisodes[0];
  const remainingEpisodes = filteredEpisodes.slice(1);

  return (
    <>
      <div className="px-4 md:px-8 py-8 md:py-10 pb-32">
        {/* Mobile Filter Bar (Hidden on Desktop because Sidebar exists) */}
        <div className="mb-6 md:hidden">
          <FilterBar />
        </div>

        {/* Hero Section (Featured Episode) */}
        <HeroSection episode={featuredEpisode} isLoading={isLoading} />

        {/* Section Header */}
        {!isLoading && !error && remainingEpisodes.length > 0 && (
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-bold text-white">
              {hasFilters ? "Filtered Results" : "Latest Episodes"}
            </h2>
            <span className="text-sm text-zinc-500">
              {remainingEpisodes.length} more
            </span>
          </div>
        )}

        {/* Episode List (skipping the first one) */}
        <EpisodeList
          episodes={remainingEpisodes}
          isLoading={isLoading && !featuredEpisode}
          error={error}
          onRetry={refreshEpisodes}
        />
      </div>

      {/* Mini Player (sticky bottom) */}
      <MiniPlayer />
    </>
  );
}
