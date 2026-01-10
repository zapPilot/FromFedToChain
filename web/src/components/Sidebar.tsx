"use client";

import { useEpisodes } from "@/hooks/use-episodes";
import {
  CATEGORY_NAMES,
  CATEGORY_EMOJIS,
  LANGUAGE_NAMES,
  LANGUAGE_FLAGS,
  type Category,
  type Language,
} from "@/types/content";

const CATEGORY_COLORS: Record<Category, string> = {
  "daily-news": "var(--accent-news)",
  ethereum: "var(--accent-ethereum)",
  macro: "var(--accent-macro)",
  startup: "var(--accent-startup)",
  ai: "var(--accent-ai)",
  defi: "var(--accent-defi)",
};

export function Sidebar() {
  const {
    selectedCategory,
    selectedLanguage,
    setCategory,
    setLanguage,
    clearFilters,
  } = useEpisodes(false);

  return (
    <aside className="w-64 h-screen fixed left-0 top-0 border-r border-white/5 bg-surface-1 hidden md:flex flex-col z-20">
      {/* Brand Header */}
      <div className="p-6">
        <div className="flex items-center gap-3 mb-1">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center text-white font-bold text-lg">
            F
          </div>
          <h1 className="font-bold text-lg tracking-tight text-white">
            Fed<span className="text-zinc-500 font-light">To</span>Chain
          </h1>
        </div>
        <p className="text-xs text-zinc-500 pl-11">Financial Intelligence</p>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto px-4 py-2 space-y-8 scrollbar-thin">
        {/* Main Section */}
        <section>
          <h3 className="px-3 text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">
            Discover
          </h3>
          <div className="space-y-1">
            <button
              onClick={clearFilters}
              className={`
                w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all
                ${!selectedCategory
                  ? "bg-white/10 text-white font-medium"
                  : "text-zinc-400 hover:text-white hover:bg-white/5"
                }
              `}
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                width="16"
                height="16"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect width="7" height="7" x="3" y="3" rx="1" />
                <rect width="7" height="7" x="14" y="3" rx="1" />
                <rect width="7" height="7" x="14" y="14" rx="1" />
                <rect width="7" height="7" x="3" y="14" rx="1" />
              </svg>
              All Episodes
            </button>
          </div>
        </section>

        {/* Categories Section */}
        <section>
          <h3 className="px-3 text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">
            Market Sectors
          </h3>
          <div className="space-y-1">
            {(Object.keys(CATEGORY_NAMES) as Category[]).map((cat) => {
              const isSelected = selectedCategory === cat;
              return (
                <button
                  key={cat}
                  onClick={() => setCategory(cat)}
                  className={`
                    w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm transition-all group
                    ${isSelected
                      ? "bg-white/10 text-white font-medium shadow-[0_0_15px_rgba(0,0,0,0.3)]"
                      : "text-zinc-400 hover:text-white hover:bg-white/5"
                    }
                  `}
                >
                  <div className="flex items-center gap-3">
                    <span
                      className={`w-1.5 h-1.5 rounded-full transition-all group-hover:scale-125 ${isSelected ? "scale-125 shadow-[0_0_8px_currentColor]" : "opacity-50"}`}
                      style={{
                        backgroundColor:
                          CATEGORY_COLORS[cat] || "var(--accent-primary)",
                      }}
                    />
                    {CATEGORY_NAMES[cat]}
                  </div>
                  {isSelected && (
                    <span className="text-xs opacity-50">
                      {CATEGORY_EMOJIS[cat]}
                    </span>
                  )}
                </button>
              );
            })}
          </div>
        </section>

        {/* Language Section - using a more compact selector style */}
        <section>
          <h3 className="px-3 text-xs font-semibold text-zinc-500 uppercase tracking-wider mb-2">
            Region
          </h3>
          <div className="grid grid-cols-3 gap-1 px-1">
            {(["en-US", "zh-TW", "ja-JP"] as Language[]).map((lang) => (
              <button
                key={lang}
                onClick={() => setLanguage(lang)}
                className={`
                  flex flex-col items-center justify-center p-2 rounded-lg border border-transparent transition-all
                  ${selectedLanguage === lang
                    ? "bg-white/10 border-white/10 text-white"
                    : "text-zinc-500 hover:bg-white/5 hover:text-zinc-300"
                  }
                `}
                title={LANGUAGE_NAMES[lang]}
              >
                <span className="text-lg mb-1 grayscale-[0.5]">
                  {LANGUAGE_FLAGS[lang]}
                </span>
                <span className="text-[10px] font-medium uppercase tracking-tighter">
                  {lang.split("-")[0]}
                </span>
              </button>
            ))}
          </div>
        </section>
      </nav>

      {/* Footer Info */}
      <div className="p-6 border-t border-white/5">
        <div className="text-xs text-zinc-600 leading-relaxed">
          <p>© 2026 From Fed to Chain.</p>
          <p>Ad-free specialized content.</p>
        </div>
      </div>
    </aside>
  );
}
