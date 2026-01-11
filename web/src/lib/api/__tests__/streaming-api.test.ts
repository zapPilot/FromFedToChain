import { StreamingApiService } from "../streaming-api";
import { ApiError } from "../streaming-api";

// Mock global fetch
global.fetch = jest.fn();

describe("StreamingApiService", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe("fetchAllEpisodes", () => {
    const mockEpisodesData = {
      episodes: [
        {
          id: "ep-1",
          title: "Episode 1",
          lastModified: "2024-03-20T12:00:00Z",
          path: "audio/en-US/daily-news/ep-1/audio.m3u8",
        },
        {
          id: "ep-2",
          title: "Episode 2",
          lastModified: "2024-03-21T12:00:00Z",
          path: "audio/en-US/daily-news/ep-2/audio.m3u8",
        },
      ],
    };

    // Suppress console logs for these tests
    let consoleErrorSpy: jest.SpyInstance;
    let consoleWarnSpy: jest.SpyInstance;
    let consoleLogSpy: jest.SpyInstance;

    beforeEach(() => {
      consoleErrorSpy = jest
        .spyOn(console, "error")
        .mockImplementation(() => {});
      consoleWarnSpy = jest.spyOn(console, "warn").mockImplementation(() => {});
      consoleLogSpy = jest.spyOn(console, "log").mockImplementation(() => {});
    });

    afterEach(() => {
      consoleErrorSpy.mockRestore();
      consoleWarnSpy.mockRestore();
      consoleLogSpy.mockRestore();
    });

    it("should fetch and parse episodes correctly", async () => {
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockEpisodesData,
      });

      const result = await StreamingApiService.fetchAllEpisodes();

      expect(result.length).toBeGreaterThan(0);

      // Episodes are sorted by date descending in parseEpisodesResponse
      // ep-2 (2024-03-21) is newer than ep-1 (2024-03-20), so it comes first
      expect(result[0]).toEqual(
        expect.objectContaining({
          id: "ep-2",
          title: "Episode 2",
          status: "published",
        }),
      );

      expect(result).toEqual(
        expect.arrayContaining([
          expect.objectContaining({
            id: "ep-1",
            title: "Episode 1",
          }),
        ]),
      );

      expect(global.fetch).toHaveBeenCalledTimes(18); // 3 langs * 6 categories
    });

    it("should handle fetch errors gracefully for individual requests", async () => {
      // Setup fetch to fail for some requests but succeed for others
      (global.fetch as jest.Mock)
        .mockResolvedValueOnce({
          ok: true,
          json: async () => mockEpisodesData,
        })
        .mockRejectedValue(new Error("Network Error")); // Fail subsequent calls

      const result = await StreamingApiService.fetchAllEpisodes();

      // Should still return episodes from the one successful request
      expect(result).toHaveLength(2);
    });
  });

  describe("filterEpisodesByQuery", () => {
    const episodes = [
      {
        id: "1",
        title: "Bitcoin Analysis",
        category: "daily-news",
        description: "Review of BTC",
        content: "Crypto content",
        language: "en-US",
        date: "2024-01-01",
        status: "published",
        streaming_urls: { m3u8: "" },
        updated_at: "",
      },
      {
        id: "2",
        title: "Ethereum Update",
        category: "ethereum",
        description: "ETH merge",
        content: "Smart contracts",
        language: "en-US",
        date: "2024-01-02",
        status: "published",
        streaming_urls: { m3u8: "" },
        updated_at: "",
      },
    ] as any[];

    it("should return all episodes if query is empty", () => {
      expect(StreamingApiService.filterEpisodesByQuery(episodes, "  ")).toBe(
        episodes,
      );
    });

    it("should filter by title", () => {
      const result = StreamingApiService.filterEpisodesByQuery(
        episodes,
        "Bitcoin",
      );
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe("1");
    });

    it("should filter by category", () => {
      const result = StreamingApiService.filterEpisodesByQuery(
        episodes,
        "ethereum",
      );
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe("2");
    });

    it("should filter by content/description", () => {
      const result = StreamingApiService.filterEpisodesByQuery(
        episodes,
        "contracts",
      );
      expect(result).toHaveLength(1);
      expect(result[0].id).toBe("2");
    });
  });

  describe("checkConnectivity", () => {
    it("should return true when API is accessible", async () => {
      // Mock fetchEpisodeList which checkConnectivity calls
      const fetchSpy = jest
        .spyOn(StreamingApiService, "fetchEpisodeList")
        .mockResolvedValue([{ id: "1" } as any]);

      const result = await StreamingApiService.checkConnectivity();
      expect(result).toBe(true);

      fetchSpy.mockRestore();
    });

    it("should return false when API fails", async () => {
      const fetchSpy = jest
        .spyOn(StreamingApiService, "fetchEpisodeList")
        .mockRejectedValue(new Error("Fail"));

      const consoleSpy = jest
        .spyOn(console, "error")
        .mockImplementation(() => {});

      const result = await StreamingApiService.checkConnectivity();
      expect(result).toBe(false);

      fetchSpy.mockRestore();
      consoleSpy.mockRestore();
    });
  });

  describe("getApiStatus", () => {
    it("should return config values", () => {
      const status = StreamingApiService.getApiStatus();
      expect(status).toHaveProperty("baseUrl");
      expect(status).toHaveProperty("supportedLanguages");
      expect(status).toHaveProperty("supportedCategories");
      expect(status).toHaveProperty("timeout");
    });
  });

  describe("fetchEpisodeContent", () => {
    it("should fetch and return content successfully", async () => {
      const mockResponse = {
        content: "Test content",
        references: ["http://ref.com"],
        social_hook: "Social hook",
        duration: 120,
      };

      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockResponse,
      });

      const result = await StreamingApiService.fetchEpisodeContent(
        "en-US",
        "ethereum",
        "test-id",
      );

      expect(result).toEqual({
        content: "Test content",
        description: "Test content", // Fallback to content
        references: ["http://ref.com"],
        social_hook: "Social hook",
        duration: 120,
      });

      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining("/api/content/en-US/ethereum/test-id"),
        expect.any(Object),
      );
    });

    it("should handle 404 not found", async () => {
      const consoleSpy = jest
        .spyOn(console, "warn")
        .mockImplementation(() => {});

      (global.fetch as jest.Mock).mockResolvedValue({
        ok: false,
        status: 404,
        statusText: "Not Found",
      });

      const result = await StreamingApiService.fetchEpisodeContent(
        "en-US",
        "ethereum",
        "unknown-id",
      );

      expect(result).toBeNull();
      expect(consoleSpy).toHaveBeenCalledWith(
        "Content not found for unknown-id",
      );

      consoleSpy.mockRestore();
    });

    it("should throw ApiError on other failures", async () => {
      // No console.error expected here since it throws, but good to be safe if implementation changes
      (global.fetch as jest.Mock).mockResolvedValue({
        ok: false,
        status: 500,
        statusText: "Internal Server Error",
      });

      await expect(
        StreamingApiService.fetchEpisodeContent("en-US", "ethereum", "test-id"),
      ).rejects.toThrow(ApiError);
    });

    it("should handle missing fields in response", async () => {
      const mockResponse = {
        // No content or references
        description: "Just description",
      };

      (global.fetch as jest.Mock).mockResolvedValue({
        ok: true,
        json: async () => mockResponse,
      });

      const result = await StreamingApiService.fetchEpisodeContent(
        "en-US",
        "ethereum",
        "test-id",
      );

      expect(result).toEqual({
        content: "",
        description: "Just description",
        references: [],
        social_hook: undefined,
        duration: undefined,
      });
    });
  });
});
