import { create } from "zustand";
import type { Episode, Language, Category } from "@/types/content";
import { StreamingApiService } from "@/lib/api/streaming-api";

/**
 * Episodes store state
 */
interface EpisodesState {
  // Data
  allEpisodes: Episode[];
  filteredEpisodes: Episode[];

  // Loading/Error states
  isLoading: boolean;
  error: string | null;

  // Filters
  selectedLanguage: Language | null; // null = all languages
  selectedCategory: Category | null; // null = all categories
  searchQuery: string;

  // Actions
  loadEpisodes: () => Promise<void>;
  setLanguage: (language: Language | null) => void;
  setCategory: (category: Category | null) => void;
  setSearchQuery: (query: string) => void;
  applyFilters: () => void;
  clearFilters: () => void;
  refreshEpisodes: () => Promise<void>;
}

/**
 * Episodes store for managing content list and filtering
 *
 * Implements Flutter's ContentService logic:
 * - Parallel loading across all languages/categories
 * - Client-side filtering by language/category
 * - Search functionality
 * - Loading/error state management
 */
export const useEpisodesStore = create<EpisodesState>((set, get) => ({
  // Initial state
  allEpisodes: [],
  filteredEpisodes: [],
  isLoading: false,
  error: null,
  selectedLanguage: null,
  selectedCategory: null,
  searchQuery: "",

  /**
   * Load all episodes from API (parallel loading)
   */
  loadEpisodes: async () => {
    set({ isLoading: true, error: null });

    try {
      const episodes = await StreamingApiService.fetchAllEpisodes();
      set({
        allEpisodes: episodes,
        isLoading: false,
      });

      // Apply current filters
      get().applyFilters();
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : "Failed to load episodes";
      set({
        isLoading: false,
        error: errorMessage,
      });
      console.error("Failed to load episodes:", error);
    }
  },

  /**
   * Set language filter
   */
  setLanguage: (language) => {
    set({ selectedLanguage: language });
    get().applyFilters();
  },

  /**
   * Set category filter
   */
  setCategory: (category) => {
    set({ selectedCategory: category });
    get().applyFilters();
  },

  /**
   * Set search query
   */
  setSearchQuery: (query) => {
    set({ searchQuery: query });
    get().applyFilters();
  },

  /**
   * Apply current filters to episodes
   */
  applyFilters: () => {
    const { allEpisodes, selectedLanguage, selectedCategory, searchQuery } =
      get();

    let filtered = [...allEpisodes];

    // Filter by language
    if (selectedLanguage) {
      filtered = filtered.filter(
        (episode) => episode.language === selectedLanguage,
      );
    }

    // Filter by category
    if (selectedCategory) {
      filtered = filtered.filter(
        (episode) => episode.category === selectedCategory,
      );
    }

    // Filter by search query
    if (searchQuery.trim()) {
      filtered = StreamingApiService.filterEpisodesByQuery(
        filtered,
        searchQuery,
      );
    }

    set({ filteredEpisodes: filtered });
  },

  /**
   * Clear all filters
   */
  clearFilters: () => {
    set({
      selectedLanguage: null,
      selectedCategory: null,
      searchQuery: "",
      filteredEpisodes: get().allEpisodes,
    });
  },

  /**
   * Refresh episodes from API
   */
  refreshEpisodes: async () => {
    await get().loadEpisodes();
  },
}));
