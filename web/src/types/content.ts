export type Category =
  | "daily-news"
  | "ethereum"
  | "macro"
  | "startup"
  | "ai"
  | "defi";

export type Language = "zh-TW" | "en-US" | "ja-JP";

export interface Episode {
  id: string;
  status: "published" | "draft";
  category: Category;
  date: string;
  language: Language;
  title: string;
  content: string;
  description?: string;
  references?: string[];
  streaming_urls?: {
    m3u8?: string;
  };
  social_hook?: string;
  updated_at: string;
  duration?: number; // Duration in seconds
  path?: string; // Original R2 path
}

export const CATEGORY_NAMES: Record<Category, string> = {
  "daily-news": "Daily News",
  ethereum: "Ethereum",
  macro: "Macro Economics",
  startup: "Startup",
  ai: "AI & Technology",
  defi: "DeFi",
};

export const CATEGORY_EMOJIS: Record<Category, string> = {
  "daily-news": "📰",
  ethereum: "⚡",
  macro: "📊",
  startup: "🚀",
  ai: "🤖",
  defi: "💎",
};

export const LANGUAGE_NAMES: Record<Language, string> = {
  "zh-TW": "繁體中文",
  "en-US": "English",
  "ja-JP": "日本語",
};

export const LANGUAGE_FLAGS: Record<Language, string> = {
  "zh-TW": "🇹🇼",
  "en-US": "🇺🇸",
  "ja-JP": "🇯🇵",
};
