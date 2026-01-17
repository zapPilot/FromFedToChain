import { renderHook } from "@testing-library/react";
import { useProgress, useMultipleProgress } from "../use-progress";
import { useProgressStore } from "@/stores/progress-store";

// Mock the store
jest.mock("@/stores/progress-store", () => ({
  useProgressStore: jest.fn(),
}));

describe("useProgress", () => {
  const mockStore = {
    progress: {
      ep1: {
        id: "ep1",
        position: 100,
        duration: 200,
        updatedAt: 123456,
        completed: false,
      },
    },
    getProgress: jest.fn(),
    updateProgress: jest.fn(),
    getResumePosition: jest.fn(),
    markCompleted: jest.fn(),
    clearProgress: jest.fn(),
    clearAllProgress: jest.fn(),
    getRecentEpisodes: jest.fn(),
    getUnfinishedEpisodes: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    (useProgressStore as unknown as jest.Mock).mockReturnValue(mockStore);
  });

  it("should return global progress methods", () => {
    const { result } = renderHook(() => useProgress());

    expect(result.current.allProgress).toBeDefined();
    expect(result.current.updateProgress).toBeDefined();
  });

  it("should return episode specific progress when episodeId is provided", () => {
    const episodeId = "ep1";
    mockStore.getProgress.mockReturnValue(mockStore.progress[episodeId]);
    mockStore.getResumePosition.mockReturnValue(100);

    const { result } = renderHook(() => useProgress(episodeId));

    expect(mockStore.getProgress).toHaveBeenCalledWith(episodeId);
    expect(result.current.progress).toEqual(mockStore.progress[episodeId]);

    expect(mockStore.getResumePosition).toHaveBeenCalledWith(episodeId);
    expect(result.current.resumePosition).toBe(100);
  });

  it("should return default values when episodeId not provided", () => {
    const { result } = renderHook(() => useProgress());

    expect(result.current.progress).toBeNull();
    expect(result.current.resumePosition).toBe(0);
  });
});

describe("useMultipleProgress", () => {
  const mockStore = {
    getProgress: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    (useProgressStore as unknown as jest.Mock).mockReturnValue(mockStore);
  });

  it("should return progress map for multiple episodes", () => {
    const episodeIds = ["ep1", "ep2"];
    const progress1 = { id: "ep1", position: 10 };
    const progress2 = { id: "ep2", position: 20 };

    mockStore.getProgress.mockImplementation((id: string) => {
      if (id === "ep1") return progress1;
      if (id === "ep2") return progress2;
      return null;
    });

    const { result } = renderHook(() => useMultipleProgress(episodeIds));

    expect(mockStore.getProgress).toHaveBeenCalledWith("ep1");
    expect(mockStore.getProgress).toHaveBeenCalledWith("ep2");
    expect(result.current.progressMap).toEqual({
      ep1: progress1,
      ep2: progress2,
    });
  });
});
