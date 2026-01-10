import { useEffect } from "react";
import { useEpisodesStore } from "@/stores/episodes-store";
import type { Language, Category } from "@/types/content";

/**
 * Hook for episodes data and filtering
 * Abstracts episodes store interactions and provides convenient access
 *
 * @param autoLoad - Whether to automatically load episodes on mount
 * @returns Episodes state, filtered list, and control functions
 */
export function useEpisodes(autoLoad: boolean = true) {
  const store = useEpisodesStore();

  // Auto-load episodes on mount if requested
  useEffect(() => {
    if (autoLoad && store.allEpisodes.length === 0 && !store.isLoading) {
      store.loadEpisodes();
    }
  }, [autoLoad, store]);

  return {
    // Data
    allEpisodes: store.allEpisodes,
    filteredEpisodes: store.filteredEpisodes,

    // Loading/Error
    isLoading: store.isLoading,
    error: store.error,

    // Filters
    selectedLanguage: store.selectedLanguage,
    selectedCategory: store.selectedCategory,
    searchQuery: store.searchQuery,

    // Actions
    loadEpisodes: store.loadEpisodes,
    setLanguage: store.setLanguage,
    setCategory: store.setCategory,
    setSearchQuery: store.setSearchQuery,
    clearFilters: store.clearFilters,
    refreshEpisodes: store.refreshEpisodes,

    // Computed
    hasFilters: Boolean(
      store.selectedLanguage || store.selectedCategory || store.searchQuery,
    ),
    episodeCount: store.filteredEpisodes.length,
    totalCount: store.allEpisodes.length,
  };
}

/**
 * Hook for a specific episode by ID
 *
 * @param episodeId - Episode ID to find
 * @returns Episode or null if not found
 */
export function useEpisode(episodeId: string | null) {
  const { allEpisodes } = useEpisodes(false);

  if (!episodeId) return null;

  return allEpisodes.find((ep) => ep.id === episodeId) ?? null;
}
