import { renderHook, waitFor } from "@testing-library/react";
import { useEpisodeContent } from "../use-episode-content";
import { StreamingApiService } from "@/lib/api/streaming-api";
import { Episode } from "@/types/content";

// Mock StreamingApiService
jest.mock("@/lib/api/streaming-api", () => ({
  StreamingApiService: {
    fetchEpisodeContent: jest.fn(),
  },
}));

describe("useEpisodeContent", () => {
  const mockEpisode: Episode = {
    id: "test-id",
    title: "Test Episode",
    description: "Test Description",
    content: "",
    category: "ethereum",
    date: "2024-03-20",
    language: "en-US",
    status: "published",
    updated_at: "2024-03-20T12:00:00Z",
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should return null content if no episode is provided", () => {
    const { result } = renderHook(() => useEpisodeContent(null));
    expect(result.current.content).toBeNull();
    expect(result.current.isLoading).toBe(false);
  });

  it("should return existing content if episode already has it", () => {
    const episodeWithContent = {
      ...mockEpisode,
      content: "Existing content",
      references: ["http://example.com"],
    };
    const { result } = renderHook(() => useEpisodeContent(episodeWithContent));

    expect(result.current.content).toBe("Existing content");
    expect(result.current.references).toEqual(["http://example.com"]);
    expect(result.current.isLoading).toBe(false);
    expect(StreamingApiService.fetchEpisodeContent).not.toHaveBeenCalled();
  });

  it("should fetch content if episode content is empty", async () => {
    (StreamingApiService.fetchEpisodeContent as jest.Mock).mockResolvedValue({
      content: "Fetched content",
      references: ["http://fetched.com"],
    });

    const { result } = renderHook(() => useEpisodeContent(mockEpisode));

    // Initially loading
    expect(result.current.isLoading).toBe(true);
    expect(result.current.content).toBeNull();

    // After fetch
    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.content).toBe("Fetched content");
    expect(result.current.references).toEqual(["http://fetched.com"]);
    expect(StreamingApiService.fetchEpisodeContent).toHaveBeenCalledWith(
      "en-US",
      "ethereum",
      "test-id",
    );
  });

  it("should handle fetch error", async () => {
    const consoleSpy = jest
      .spyOn(console, "error")
      .mockImplementation(() => {});

    (StreamingApiService.fetchEpisodeContent as jest.Mock).mockRejectedValue(
      new Error("Network error"),
    );

    const { result } = renderHook(() => useEpisodeContent(mockEpisode));

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.content).toBeNull();
    expect(result.current.error).toBe("Network error");
    expect(consoleSpy).toHaveBeenCalledWith(
      "Error fetching episode content:",
      expect.any(Error),
    );

    consoleSpy.mockRestore();
  });

  it("should handle missing content in response", async () => {
    (StreamingApiService.fetchEpisodeContent as jest.Mock).mockResolvedValue(
      null,
    );

    const { result } = renderHook(() => useEpisodeContent(mockEpisode));

    await waitFor(() => expect(result.current.isLoading).toBe(false));

    expect(result.current.content).toBeNull();
    expect(result.current.error).toBe(
      "Content not available for this episode.",
    );
  });
});
