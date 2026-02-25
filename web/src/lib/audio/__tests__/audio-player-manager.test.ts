import { AudioPlayerManager } from "../audio-player-manager";
import { useAudioPlayerStore } from "@/stores/audio-player-store";
import { useProgressStore } from "@/stores/progress-store";
import Hls from "hls.js";
import type { Episode } from "@/types/content";

type MockAudioElement = {
  addEventListener: jest.Mock;
  removeEventListener: jest.Mock;
  play: jest.Mock<Promise<void>, []>;
  pause: jest.Mock<void, []>;
  canPlayType: jest.Mock<string, [string]>;
  src: string;
  currentTime: number;
  duration: number;
  playbackRate: number;
  error: { code: number } | null;
};

type MockStore = {
  updateDuration: jest.Mock;
  updateState: jest.Mock;
  updatePosition: jest.Mock;
  updateSpeed: jest.Mock;
  onPlaybackCompleted: jest.Mock;
  setError: jest.Mock;
  setCurrentEpisode: jest.Mock;
  reset: jest.Mock;
  playbackState: string;
  playbackSpeed: number;
};

type MockProgressStore = {
  updateProgress: jest.Mock;
  getResumePosition: jest.Mock;
};

function createEpisode(): Episode {
  return {
    id: "1",
    title: "Test Episode",
    status: "published",
    category: "daily-news",
    date: "2024-01-01",
    language: "en-US",
    content: "",
    updated_at: "2024-01-01T00:00:00Z",
    streaming_urls: { m3u8: "test.m3u8" },
  };
}

// Mock dependencies
jest.mock("@/stores/audio-player-store", () => ({
  useAudioPlayerStore: {
    getState: jest.fn(),
  },
}));

jest.mock("@/stores/progress-store", () => ({
  useProgressStore: {
    getState: jest.fn(),
  },
}));

// Mock Hls.js
jest.mock("hls.js", () => {
  const mockHlsInstance = {
    on: jest.fn(),
    loadSource: jest.fn(),
    attachMedia: jest.fn(),
    destroy: jest.fn(),
    recoverMediaError: jest.fn(),
    startLoad: jest.fn(),
  };

  const HlsMock = Object.assign(
    jest.fn(() => mockHlsInstance),
    {
      Events: { ERROR: "hlsError" },
      ErrorTypes: {
        NETWORK_ERROR: "networkError",
        MEDIA_ERROR: "mediaError",
      },
      isSupported: jest.fn().mockReturnValue(true),
    },
  );

  return {
    __esModule: true,
    default: HlsMock,
  };
});

describe("AudioPlayerManager", () => {
  let manager: AudioPlayerManager;
  let mockAudio: MockAudioElement;
  let mockStore: MockStore;
  let mockProgressStore: MockProgressStore;

  function getRegisteredHandler(eventName: string): () => void {
    const handlerEntry = mockAudio.addEventListener.mock.calls.find(
      (call: unknown[]) => call[0] === eventName,
    );

    if (!handlerEntry) {
      throw new Error(`Expected handler for event: ${eventName}`);
    }

    return handlerEntry[1] as () => void;
  }

  beforeAll(() => {
    if (typeof MediaError === "undefined") {
      Object.defineProperty(globalThis, "MediaError", {
        configurable: true,
        value: {
          MEDIA_ERR_ABORTED: 1,
          MEDIA_ERR_NETWORK: 2,
          MEDIA_ERR_DECODE: 3,
          MEDIA_ERR_SRC_NOT_SUPPORTED: 4,
        },
      });
    }
  });

  beforeEach(() => {
    jest.clearAllMocks();
    jest.useFakeTimers();

    // Mock Audio element
    mockAudio = {
      addEventListener: jest.fn(),
      removeEventListener: jest.fn(),
      play: jest.fn().mockResolvedValue(undefined),
      pause: jest.fn(),
      canPlayType: jest.fn().mockReturnValue(""),
      src: "",
      currentTime: 0,
      duration: 100,
      playbackRate: 1,
      error: null,
    };
    global.Audio = jest
      .fn()
      .mockImplementation(() => mockAudio) as unknown as typeof Audio;

    // Mock stores
    mockStore = {
      updateDuration: jest.fn(),
      updateState: jest.fn(),
      updatePosition: jest.fn(),
      updateSpeed: jest.fn(),
      onPlaybackCompleted: jest.fn(),
      setError: jest.fn(),
      setCurrentEpisode: jest.fn(),
      reset: jest.fn(),
      playbackState: "stopped",
      playbackSpeed: 1,
    };
    (useAudioPlayerStore.getState as jest.Mock).mockReturnValue(mockStore);

    mockProgressStore = {
      updateProgress: jest.fn(),
      getResumePosition: jest.fn().mockReturnValue(0),
    };
    (useProgressStore.getState as jest.Mock).mockReturnValue(mockProgressStore);

    // Reset singleton instance
    (
      AudioPlayerManager as unknown as {
        instance: AudioPlayerManager | null;
      }
    ).instance = null;

    manager = AudioPlayerManager.getInstance();
  });

  afterEach(() => {
    jest.useRealTimers();
    manager.destroy();
  });

  it("should be a singleton", () => {
    const instance1 = AudioPlayerManager.getInstance();
    const instance2 = AudioPlayerManager.getInstance();
    expect(instance1).toBe(instance2);
  });

  describe("play", () => {
    it("should use native HLS if supported", async () => {
      mockAudio.canPlayType.mockReturnValue("maybe");
      const episode = createEpisode();

      mockAudio.addEventListener.mockImplementation(
        (event: string, callback: () => void) => {
          if (event === "canplay") {
            callback();
          }
        },
      );

      await manager.play(episode);

      expect(mockAudio.src).toBe("test.m3u8");
      expect(mockAudio.play).toHaveBeenCalled();
    });

    it("should use hls.js if native HLS not supported", async () => {
      mockAudio.canPlayType.mockReturnValue("");
      (
        Hls as unknown as { isSupported: jest.Mock }
      ).isSupported.mockReturnValue(true);

      const episode = createEpisode();

      mockAudio.addEventListener.mockImplementation(
        (event: string, callback: () => void) => {
          if (event === "canplay") {
            callback();
          }
        },
      );

      await manager.play(episode);

      expect(Hls).toHaveBeenCalled();
      const hlsInstance = (Hls as unknown as jest.Mock).mock.results[0]
        .value as {
        loadSource: jest.Mock;
        attachMedia: jest.Mock;
      };
      expect(hlsInstance.loadSource).toHaveBeenCalledWith("test.m3u8");
      expect(hlsInstance.attachMedia).toHaveBeenCalledWith(mockAudio);
    });

    it("should skip if same episode already loaded", async () => {
      const episode = createEpisode();

      mockAudio.addEventListener.mockImplementation(
        (event: string, callback: () => void) => {
          if (event === "canplay") {
            callback();
          }
        },
      );

      await manager.play(episode);
      mockAudio.play.mockClear();
      await manager.play(episode);

      expect(Hls).toHaveBeenCalledTimes(1);
    });
  });

  describe("Audio logic", () => {
    it("should handle standard audio errors", () => {
      const handler = getRegisteredHandler("error");

      mockAudio.error = { code: 1 }; // MEDIA_ERR_ABORTED
      handler();
      expect(mockStore.setError).toHaveBeenCalledWith("Playback aborted");
    });
  });

  describe("Progress Tracking", () => {
    it("should start and stop tracking on play/pause", () => {
      const episode = createEpisode();
      (
        manager as unknown as {
          currentEpisode: Episode | null;
        }
      ).currentEpisode = episode;

      const playHandler = getRegisteredHandler("playing");
      playHandler();

      jest.advanceTimersByTime(1000);
      expect(mockProgressStore.updateProgress).toHaveBeenCalled();

      mockProgressStore.updateProgress.mockClear();

      const pauseHandler = getRegisteredHandler("pause");
      pauseHandler();

      expect(mockProgressStore.updateProgress).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(1000);
      expect(mockProgressStore.updateProgress).toHaveBeenCalledTimes(1);
    });
  });
});
