import { useEffect } from "react";
import { useSearchParams, useRouter, usePathname } from "next/navigation";
import { useEpisodesStore } from "@/stores/episodes-store";
import type { Language, Category } from "@/types/content";
import { LANGUAGE_NAMES, CATEGORY_NAMES } from "@/types/content";

// Derive supported values from the exported constants
const SUPPORTED_LANGUAGES = Object.keys(LANGUAGE_NAMES) as Language[];
const SUPPORTED_CATEGORIES = Object.keys(CATEGORY_NAMES) as Category[];

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

  // URL Synchronization
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  // 1. Initialize Store from URL on mount
  useEffect(() => {
    const langParam = searchParams.get("lang");
    const catParam = searchParams.get("category");

    if (langParam && langParam !== store.selectedLanguage) {
      if (SUPPORTED_LANGUAGES.includes(langParam as Language)) {
        store.setLanguage(langParam as Language);
      }
    }

    if (catParam && catParam !== store.selectedCategory) {
      if (SUPPORTED_CATEGORIES.includes(catParam as Category)) {
        store.setCategory(catParam as Category);
      }
    }
  }, []); // Run once on mount

  // 2. Update URL when Store changes
  useEffect(() => {
    const params = new URLSearchParams(searchParams.toString());
    let hasChanges = false;

    // Sync Language
    if (store.selectedLanguage) {
      if (params.get("lang") !== store.selectedLanguage) {
        params.set("lang", store.selectedLanguage);
        hasChanges = true;
      }
    } else {
      if (params.has("lang")) {
        params.delete("lang");
        hasChanges = true;
      }
    }

    // Sync Category
    if (store.selectedCategory) {
      if (params.get("category") !== store.selectedCategory) {
        params.set("category", store.selectedCategory);
        hasChanges = true;
      }
    } else {
      if (params.has("category")) {
        params.delete("category");
        hasChanges = true;
      }
    }

    if (hasChanges) {
      router.replace(`${pathname}?${params.toString()}`);
    }
  }, [
    store.selectedLanguage,
    store.selectedCategory,
    router,
    pathname,
    searchParams,
  ]);

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
