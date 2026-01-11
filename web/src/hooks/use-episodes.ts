import { useEffect, useRef } from "react";
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

  // Track if initial URL sync is done
  const hasInitializedFromUrl = useRef(false);
  // Track if we're doing a programmatic URL update
  const isProgrammaticUrlUpdate = useRef(false);
  // Track last synced values to prevent loops
  const lastSyncedParams = useRef({ lang: "", category: "" });

  // URL Synchronization
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();

  // Get current URL params
  const langParam = searchParams.get("lang") ?? "";
  const catParam = searchParams.get("category") ?? "";

  // 1. Sync URL → Store: On mount and when URL changes externally
  useEffect(() => {
    // Skip if this URL change was caused by our store→URL sync
    if (isProgrammaticUrlUpdate.current) {
      isProgrammaticUrlUpdate.current = false;
      return;
    }

    // Parse URL params
    const targetLang =
      langParam && SUPPORTED_LANGUAGES.includes(langParam as Language)
        ? (langParam as Language)
        : null;

    const targetCat =
      catParam && SUPPORTED_CATEGORIES.includes(catParam as Category)
        ? (catParam as Category)
        : null;

    // Get current store state directly from store (avoid stale closure)
    const currentState = useEpisodesStore.getState();

    // Only update if different
    if (targetLang !== currentState.selectedLanguage) {
      currentState.setLanguage(targetLang);
    }
    if (targetCat !== currentState.selectedCategory) {
      currentState.setCategory(targetCat);
    }

    // Update last synced values
    lastSyncedParams.current = { lang: langParam, category: catParam };
    hasInitializedFromUrl.current = true;
  }, [langParam, catParam]); // Only depend on URL param values

  // Auto-load episodes
  useEffect(() => {
    if (autoLoad && store.allEpisodes.length === 0 && !store.isLoading) {
      store.loadEpisodes();
    }
  }, [autoLoad, store]);

  // 2. Sync Store → URL: When user changes filter via UI (store changes)
  useEffect(() => {
    // Don't sync until initial URL→Store sync is done
    if (!hasInitializedFromUrl.current) return;

    const newLang = store.selectedLanguage ?? "";
    const newCat = store.selectedCategory ?? "";

    // Skip if values match what we last synced from URL
    if (
      newLang === lastSyncedParams.current.lang &&
      newCat === lastSyncedParams.current.category
    ) {
      return;
    }

    // Build new URL
    const params = new URLSearchParams();
    if (store.selectedLanguage) {
      params.set("lang", store.selectedLanguage);
    }
    if (store.selectedCategory) {
      params.set("category", store.selectedCategory);
    }

    // Update last synced values
    lastSyncedParams.current = { lang: newLang, category: newCat };

    // Set flag to skip the URL→Store sync for this update
    isProgrammaticUrlUpdate.current = true;

    const newUrl = params.toString()
      ? `${pathname}?${params.toString()}`
      : pathname;
    router.replace(newUrl);
  }, [store.selectedLanguage, store.selectedCategory, router, pathname]);

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
