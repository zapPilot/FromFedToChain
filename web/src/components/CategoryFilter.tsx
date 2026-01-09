"use client";

import { Category, CATEGORY_NAMES, CATEGORY_EMOJIS } from "@/types/content";

interface CategoryFilterProps {
  selectedCategory?: Category | null;
  onCategoryChange: (category: Category | null) => void;
}

export default function CategoryFilter({
  selectedCategory,
  onCategoryChange,
}: CategoryFilterProps) {
  const categories: Category[] = [
    "daily-news",
    "ethereum",
    "macro",
    "startup",
    "ai",
    "defi",
  ];
  const allCategories: (Category | null)[] = [null, ...categories];

  return (
    <div className="flex flex-wrap gap-2 mb-6">
      {allCategories.map((category) => {
        const isSelected = selectedCategory === category;
        const label = category
          ? `${CATEGORY_EMOJIS[category]} ${CATEGORY_NAMES[category]}`
          : "All";

        return (
          <button
            key={category || "all"}
            onClick={() => onCategoryChange(category)}
            className={`
              px-4 py-2 rounded-full text-sm font-medium transition-all
              ${
                isSelected
                  ? "bg-white text-black"
                  : "bg-zinc-900 text-zinc-300 hover:bg-zinc-800"
              }
            `}
          >
            {label}
          </button>
        );
      })}
    </div>
  );
}
