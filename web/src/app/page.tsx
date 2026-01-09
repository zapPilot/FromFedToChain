"use client";

import { useState } from "react";
import { Category } from "@/types/content";
import { mockEpisodes, getEpisodesByCategory } from "@/data/mock-content";
import EpisodeCard from "@/components/EpisodeCard";
import CategoryFilter from "@/components/CategoryFilter";

export default function Home() {
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(
    null,
  );
  const episodes = getEpisodesByCategory(selectedCategory || undefined);

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8">
          <h1 className="text-4xl font-bold mb-4">Latest Episodes</h1>
          <p className="text-zinc-400 text-lg">
            Stay updated with the latest insights on crypto, macro economics,
            and blockchain technology.
          </p>
        </div>

        <CategoryFilter
          selectedCategory={selectedCategory}
          onCategoryChange={setSelectedCategory}
        />

        <div className="space-y-4">
          {episodes.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-zinc-400">
                No episodes found in this category.
              </p>
            </div>
          ) : (
            episodes.map((episode) => (
              <EpisodeCard key={episode.id} episode={episode} />
            ))
          )}
        </div>
      </div>
    </div>
  );
}
