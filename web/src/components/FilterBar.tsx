"use client";

import { useEpisodes } from "@/hooks/use-episodes";
import {
  CATEGORY_NAMES,
  CATEGORY_EMOJIS,
  LANGUAGE_NAMES,
  LANGUAGE_FLAGS,
  type Language,
  type Category,
} from "@/types/content";

/**
 * Filter bar component for language and category selection
 * Horizontal scrollable chips with emoji indicators
 */
export function FilterBar() {
  const {
    selectedLanguage,
    selectedCategory,
    setLanguage,
    setCategory,
    clearFilters,
    hasFilters,
  } = useEpisodes(false);

  const languages: (Language | null)[] = [null, "zh-TW", "en-US", "ja-JP"];
  const categories: (Category | null)[] = [
    null,
    "daily-news",
    "ethereum",
    "macro",
    "startup",
    "ai",
    "defi",
  ];

  return (
    <div className="space-y-4">
      {/* Language Filter */}
      <div className="space-y-2">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-medium text-zinc-400">Language</h3>
          {hasFilters && (
            <button
              onClick={clearFilters}
              className="text-xs text-zinc-500 hover:text-zinc-300 transition-colors"
            >
              Clear All
            </button>
          )}
        </div>
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-zinc-700 scrollbar-track-transparent">
          {languages.map((lang) => {
            const isSelected = selectedLanguage === lang;
            const isAll = lang === null;

            return (
              <button
                key={lang || "all-lang"}
                onClick={() => setLanguage(lang)}
                className={`
                  flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium
                  whitespace-nowrap transition-all
                  ${
                    isSelected
                      ? "bg-zinc-700 text-zinc-100 shadow-lg"
                      : "bg-zinc-800 text-zinc-400 hover:bg-zinc-750 hover:text-zinc-200"
                  }
                `}
              >
                {isAll ? (
                  "🌐 All Languages"
                ) : (
                  <>
                    {LANGUAGE_FLAGS[lang!]} {LANGUAGE_NAMES[lang!]}
                  </>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Category Filter */}
      <div className="space-y-2">
        <h3 className="text-sm font-medium text-zinc-400">Category</h3>
        <div className="flex gap-2 overflow-x-auto pb-2 scrollbar-thin scrollbar-thumb-zinc-700 scrollbar-track-transparent">
          {categories.map((cat) => {
            const isSelected = selectedCategory === cat;
            const isAll = cat === null;

            return (
              <button
                key={cat || "all-cat"}
                onClick={() => setCategory(cat)}
                className={`
                  flex items-center gap-2 px-4 py-2 rounded-full text-sm font-medium
                  whitespace-nowrap transition-all
                  ${
                    isSelected
                      ? "bg-zinc-700 text-zinc-100 shadow-lg"
                      : "bg-zinc-800 text-zinc-400 hover:bg-zinc-750 hover:text-zinc-200"
                  }
                `}
              >
                {isAll ? (
                  "📚 All Categories"
                ) : (
                  <>
                    {CATEGORY_EMOJIS[cat!]} {CATEGORY_NAMES[cat!]}
                  </>
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
