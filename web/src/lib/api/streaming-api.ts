import type { Episode, Language, Category } from "@/types/content";

/**
 * API configuration for Cloudflare Worker streaming service
 */
const API_CONFIG = {
  baseUrl: "https://signed-url.davidtnfsh.workers.dev",
  timeout: 30000, // 30 seconds
  supportedLanguages: ["zh-TW", "en-US", "ja-JP"] as const,
  supportedCategories: [
    "daily-news",
    "ethereum",
    "macro",
    "startup",
    "ai",
    "defi",
  ] as const,
} as const;

/**
 * API response types from Cloudflare Worker
 */
interface ApiEpisode {
  path: string;
  id?: string;
  title?: string;
  category?: string;
  language?: string;
  lastModified?: string;
  size?: number;
  [key: string]: unknown;
}

/**
 * API error types
 */
export class ApiError extends Error {
  constructor(
    message: string,
    public statusCode?: number,
    public originalError?: unknown,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export class NetworkError extends ApiError {
  constructor(message: string, originalError?: unknown) {
    super(message, undefined, originalError);
    this.name = "NetworkError";
  }
}

export class TimeoutError extends ApiError {
  constructor(message: string) {
    super(message);
    this.name = "TimeoutError";
  }
}

/**
 * Service for interacting with the Cloudflare R2 streaming API
 * Handles episode discovery and streaming URL generation
 */
export class StreamingApiService {
  /**
   * Get list URL for a language and category
   */
  private static getListUrl(language: Language, category: Category): string {
    return `${API_CONFIG.baseUrl}?prefix=audio/${language}/${category}/`;
  }

  /**
   * Get streaming URL for a given path
   */
  private static getStreamUrl(path: string): string {
    return `${API_CONFIG.baseUrl}/proxy/${path}`;
  }

  /**
   * Fetch with timeout support
   */
  private static async fetchWithTimeout(
    url: string,
    timeout: number = API_CONFIG.timeout,
  ): Promise<Response> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeout);

    try {
      const response = await fetch(url, {
        signal: controller.signal,
        headers: {
          Accept: "application/json",
        },
      });
      clearTimeout(timeoutId);
      return response;
    } catch (error) {
      clearTimeout(timeoutId);
      if (
        error instanceof Error &&
        (error.name === "AbortError" || error.message.includes("aborted"))
      ) {
        throw new TimeoutError(`Request timed out after ${timeout}ms`);
      }
      throw new NetworkError(
        `Network connection error: ${error instanceof Error ? error.message : "Unknown error"}`,
        error,
      );
    }
  }

  /**
   * Parse API response into Episode objects
   */
  private static parseEpisodesResponse(
    responseData: unknown,
    language: Language,
    category: Category,
  ): Episode[] {
    let episodeData: ApiEpisode[];

    // Handle both array and object responses
    if (Array.isArray(responseData)) {
      episodeData = responseData;
    } else if (
      typeof responseData === "object" &&
      responseData !== null &&
      "episodes" in responseData
    ) {
      episodeData = (responseData as { episodes: ApiEpisode[] }).episodes;
    } else if (
      typeof responseData === "object" &&
      responseData !== null &&
      "data" in responseData
    ) {
      episodeData = (responseData as { data: ApiEpisode[] }).data;
    } else if (
      typeof responseData === "object" &&
      responseData !== null &&
      "files" in responseData
    ) {
      episodeData = (responseData as { files: ApiEpisode[] }).files;
    } else if (typeof responseData === "object" && responseData !== null) {
      // Single episode object
      episodeData = [responseData as ApiEpisode];
    } else {
      throw new Error(`Unexpected response format: ${typeof responseData}`);
    }

    const episodes: Episode[] = [];

    for (const episodeJson of episodeData) {
      try {
        const path = episodeJson.path;
        if (!path) {
          console.warn("Skipping episode with missing path:", episodeJson);
          continue;
        }

        // Build streaming URL
        const streamingUrl = this.getStreamUrl(path);

        // Extract ID from path (format: audio/language/category/id/audio.m3u8)
        const pathParts = path.split("/");
        const id =
          pathParts.length >= 4 ? pathParts[3] : episodeJson.id || path;

        // Parse date from ID if it starts with YYYY-MM-DD
        const dateMatch = id.match(/^(\d{4}-\d{2}-\d{2})/);
        const date = dateMatch
          ? dateMatch[1]
          : episodeJson.lastModified || new Date().toISOString();

        // Create Episode object
        const episode: Episode = {
          id,
          status: "published",
          category,
          date,
          language,
          title: episodeJson.title || id,
          content: "",
          streaming_urls: {
            m3u8: streamingUrl,
          },
          updated_at: episodeJson.lastModified || new Date().toISOString(),
        };

        episodes.push(episode);
      } catch (error) {
        console.warn("Failed to parse episode:", episodeJson, error);
      }
    }

    return episodes;
  }

  /**
   * Get list of episodes for a specific language and category
   */
  static async fetchEpisodeList(
    language: Language,
    category: Category,
  ): Promise<Episode[]> {
    const url = this.getListUrl(language, category);

    try {
      const response = await this.fetchWithTimeout(url);

      if (!response.ok) {
        throw new ApiError(
          `Failed to load episodes: ${response.status} - ${response.statusText}`,
          response.status,
        );
      }

      const responseData = await response.json();
      return this.parseEpisodesResponse(responseData, language, category);
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      throw new ApiError(
        `Unexpected error fetching episodes: ${error instanceof Error ? error.message : "Unknown error"}`,
        undefined,
        error,
      );
    }
  }

  /**
   * Get all episodes for a specific language across all categories
   */
  static async fetchAllEpisodesForLanguage(
    language: Language,
  ): Promise<Episode[]> {
    const allEpisodes: Episode[] = [];
    const errors: string[] = [];

    // Load episodes from all categories in parallel
    const promises = API_CONFIG.supportedCategories.map(async (category) => {
      try {
        const episodes = await this.fetchEpisodeList(
          language,
          category as Category,
        );
        return episodes;
      } catch (error) {
        errors.push(
          `${category}: ${error instanceof Error ? error.message : "Unknown error"}`,
        );
        return [] as Episode[];
      }
    });

    const results = await Promise.all(promises);

    // Flatten results
    for (const episodeList of results) {
      allEpisodes.push(...episodeList);
    }

    if (errors.length > 0) {
      console.warn(
        `Some categories failed for ${language}: ${errors.join(", ")}`,
      );
    }

    // Sort by date (newest first)
    allEpisodes.sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
    );

    return allEpisodes;
  }

  /**
   * Get all episodes across all languages and categories (parallel loading)
   * This creates 3 languages × 6 categories = 18 parallel requests
   */
  static async fetchAllEpisodes(): Promise<Episode[]> {
    console.log("Starting parallel loading of all episodes...");

    const allEpisodes: Episode[] = [];
    const errors: string[] = [];

    // Create all API calls upfront for parallel execution
    const promises: Promise<Episode[]>[] = [];

    for (const language of API_CONFIG.supportedLanguages) {
      for (const category of API_CONFIG.supportedCategories) {
        const promise = this.fetchEpisodeList(
          language as Language,
          category as Category,
        ).catch((error) => {
          errors.push(
            `${language}/${category}: ${error instanceof Error ? error.message : "Unknown error"}`,
          );
          return [] as Episode[];
        });
        promises.push(promise);
      }
    }

    console.log(`Created ${promises.length} parallel requests`);

    // Wait for all requests to complete (parallel execution)
    const results = await Promise.all(promises);

    // Flatten results
    for (const episodeList of results) {
      allEpisodes.push(...episodeList);
    }

    if (errors.length > 0) {
      console.warn(`Some requests failed: ${errors.join(", ")}`);
    }

    // Sort by date (newest first)
    allEpisodes.sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime(),
    );

    console.log(
      `Parallel loading completed, got ${allEpisodes.length} total episodes`,
    );
    return allEpisodes;
  }

  /**
   * Filter episodes by search query (client-side filtering)
   */
  static filterEpisodesByQuery(episodes: Episode[], query: string): Episode[] {
    if (!query.trim()) return episodes;

    const lowerQuery = query.toLowerCase();
    return episodes.filter((episode) => {
      return (
        episode.title.toLowerCase().includes(lowerQuery) ||
        episode.id.toLowerCase().includes(lowerQuery) ||
        episode.category.toLowerCase().includes(lowerQuery) ||
        episode.description?.toLowerCase().includes(lowerQuery) ||
        episode.content?.toLowerCase().includes(lowerQuery)
      );
    });
  }

  /**
   * Test connectivity to the streaming API
   */
  static async checkConnectivity(): Promise<boolean> {
    try {
      const episodes = await this.fetchEpisodeList("zh-TW", "startup");
      return episodes.length > 0;
    } catch (error) {
      console.error("API connectivity test failed:", error);
      return false;
    }
  }

  /**
   * Get API status information
   */
  static getApiStatus() {
    return {
      baseUrl: API_CONFIG.baseUrl,
      supportedLanguages: API_CONFIG.supportedLanguages,
      supportedCategories: API_CONFIG.supportedCategories,
      timeout: API_CONFIG.timeout,
    };
  }
}
