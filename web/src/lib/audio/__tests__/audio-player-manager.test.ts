import { AudioPlayerManager } from "../audio-player-manager";
import { useAudioPlayerStore } from "@/stores/audio-player-store";
import { useProgressStore } from "@/stores/progress-store";
import Hls from "hls.js";

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

  const HlsMock = jest.fn(() => mockHlsInstance);
  (HlsMock as any).Events = { ERROR: "hlsError" };
  (HlsMock as any).ErrorTypes = {
    NETWORK_ERROR: "networkError",
    MEDIA_ERROR: "mediaError",
  };
  (HlsMock as any).isSupported = jest.fn().mockReturnValue(true);

  return {
    __esModule: true,
    default: HlsMock,
  };
});

describe("AudioPlayerManager", () => {
  let manager: AudioPlayerManager;
  let mockAudio: any;
  let mockStore: any;
  let mockProgressStore: any;

  beforeAll(() => {
    if (typeof MediaError === "undefined") {
      global.MediaError = {
        MEDIA_ERR_ABORTED: 1,
        MEDIA_ERR_NETWORK: 2,
        MEDIA_ERR_DECODE: 3,
        MEDIA_ERR_SRC_NOT_SUPPORTED: 4,
      } as any;
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
    global.Audio = jest.fn().mockImplementation(() => mockAudio) as any;

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
    (AudioPlayerManager as any).instance = null;

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
      const episode: any = { id: "1", streaming_urls: { m3u8: "test.m3u8" } };

      mockAudio.addEventListener.mockImplementation(
        (event: string, callback: any) => {
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
      (Hls as any).isSupported.mockReturnValue(true);

      const episode: any = { id: "1", streaming_urls: { m3u8: "test.m3u8" } };

      mockAudio.addEventListener.mockImplementation(
        (event: string, callback: any) => {
          if (event === "canplay") {
            callback();
          }
        },
      );

      await manager.play(episode);

      expect(Hls).toHaveBeenCalled();
      const hlsInstance = (Hls as unknown as jest.Mock).mock.results[0].value;
      expect(hlsInstance.loadSource).toHaveBeenCalledWith("test.m3u8");
      expect(hlsInstance.attachMedia).toHaveBeenCalledWith(mockAudio);
    });

    it("should skip if same episode already loaded", async () => {
      const episode: any = { id: "1", streaming_urls: { m3u8: "test.m3u8" } };
      // Setup current episode logic
      // We can't access private property directly easily, but we can play once then play again
      mockAudio.addEventListener.mockImplementation(
        (event: string, callback: any) => {
          if (event === "canplay") {
            callback();
          }
        },
      );

      await manager.play(episode);
      mockAudio.play.mockClear();
      // Play same episode
      await manager.play(episode);

      // Should load once (first play), but not second time
      expect(Hls).toHaveBeenCalledTimes(1);
      // Wait, did the first play use Hls?
      // Need to configure support. Default is empty canPlayType in beforeEach.
      // So Hls used. Hls constructor called once.
      // Second play: should NOT call Hls constructor again if skipped.

      // Actually since we reset mocks in beforeEach, verify clean slate.
      // But Hls mock history is cleared? Yes.
    });
  });

  describe("Audio logic", () => {
    it("should handle standard audio errors", () => {
      const handler = mockAudio.addEventListener.mock.calls.find(
        (call: any) => call[0] === "error",
      )[1];

      mockAudio.error = { code: 1 }; // MEDIA_ERR_ABORTED
      handler();
      expect(mockStore.setError).toHaveBeenCalledWith("Playback aborted");
    });
  });

  describe("Progress Tracking", () => {
    it("should start and stop tracking on play/pause", async () => {
      // Setup current episode to allow progress update
      const episode: any = { id: "1", streaming_urls: { m3u8: "test.m3u8" } };
      (manager as any).currentEpisode = episode;

      // Play triggers tracking
      const playHandler = mockAudio.addEventListener.mock.calls.find(
        (call: any) => call[0] === "playing",
      )[1];
      playHandler();

      // Advance time
      jest.advanceTimersByTime(1000);
      expect(mockProgressStore.updateProgress).toHaveBeenCalled();

      mockProgressStore.updateProgress.mockClear();

      // Pause triggers stop tracking AND immediate update
      const pauseHandler = mockAudio.addEventListener.mock.calls.find(
        (call: any) => call[0] === "pause",
      )[1];
      pauseHandler();

      // Immediate update happened
      expect(mockProgressStore.updateProgress).toHaveBeenCalledTimes(1);

      // Advance time - should not call again
      jest.advanceTimersByTime(1000);
      expect(mockProgressStore.updateProgress).toHaveBeenCalledTimes(1);
    });
  });
});
