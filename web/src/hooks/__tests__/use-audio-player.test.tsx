import { renderHook, act } from "@testing-library/react";
import { useAudioPlayer } from "../use-audio-player";
import { useAudioPlayerStore } from "@/stores/audio-player-store";
import { getAudioPlayerManager } from "@/lib/audio/audio-player-manager";

// Mock the dependencies
jest.mock("@/stores/audio-player-store", () => ({
  useAudioPlayerStore: jest.fn(),
}));

jest.mock("@/lib/audio/audio-player-manager", () => ({
  getAudioPlayerManager: jest.fn(),
}));

describe("useAudioPlayer", () => {
  const mockStore = {
    currentEpisode: null,
    playbackState: "stopped",
    currentPosition: 0,
    totalDuration: 0,
    playbackSpeed: 1,
    errorMessage: null,
    isPlaying: jest.fn(),
    isPaused: jest.fn(),
    isLoading: jest.fn(),
    hasError: jest.fn(),
    isIdle: jest.fn(),
    isCompleted: jest.fn(),
    progress: jest.fn(),
    formattedCurrentPosition: jest.fn(),
    formattedTotalDuration: jest.fn(),
    play: jest.fn(),
    pause: jest.fn(),
    seek: jest.fn(),
    setSpeed: jest.fn(),
    skipForward: jest.fn(),
    skipBackward: jest.fn(),
    stop: jest.fn(),
  };

  const mockAudioManager = {
    play: jest.fn(),
    pause: jest.fn(),
    seek: jest.fn(),
    setSpeed: jest.fn(),
    skipForward: jest.fn(),
    skipBackward: jest.fn(),
    stop: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
    (useAudioPlayerStore as unknown as jest.Mock).mockReturnValue(mockStore);
    (useAudioPlayerStore as unknown as jest.Mock).mockImplementation(
      () => mockStore,
    );
    // @ts-ignore
    useAudioPlayerStore.setState = jest.fn();
    (getAudioPlayerManager as jest.Mock).mockReturnValue(mockAudioManager);
  });

  it("should return the store state and methods", () => {
    const { result } = renderHook(() => useAudioPlayer());

    expect(result.current.currentEpisode).toBeNull();
    expect(result.current.play).toBeDefined();
    expect(result.current.pause).toBeDefined();
  });

  it("should initialize audio manager integration on mount", () => {
    renderHook(() => useAudioPlayer());

    expect(getAudioPlayerManager).toHaveBeenCalled();
    // Check if store actions were overridden
    expect(useAudioPlayerStore.setState).toHaveBeenCalled();
  });

  it("should override play action to use audio manager (with episode)", async () => {
    renderHook(() => useAudioPlayer());

    const setStateCall = (useAudioPlayerStore.setState as unknown as jest.Mock)
      .mock.calls[0][0];
    const episode = { id: "1", title: "Test" } as any;

    await setStateCall.play(episode);
    expect(mockAudioManager.play).toHaveBeenCalledWith(episode);
  });

  it("should override play action to use audio manager (no episode)", async () => {
    renderHook(() => useAudioPlayer());

    const setStateCall = (useAudioPlayerStore.setState as unknown as jest.Mock)
      .mock.calls[0][0];

    await setStateCall.play();
    expect(mockAudioManager.play).toHaveBeenCalledWith();
  });

  it("should override pause action to use audio manager", () => {
    renderHook(() => useAudioPlayer());
    const setStateCall = (useAudioPlayerStore.setState as unknown as jest.Mock)
      .mock.calls[0][0];

    setStateCall.pause();
    expect(mockAudioManager.pause).toHaveBeenCalled();
  });

  it("should override seek action to use audio manager", () => {
    renderHook(() => useAudioPlayer());
    const setStateCall = (useAudioPlayerStore.setState as unknown as jest.Mock)
      .mock.calls[0][0];

    setStateCall.seek(100);
    expect(mockAudioManager.seek).toHaveBeenCalledWith(100);
  });

  it("should override setSpeed action to use audio manager", () => {
    renderHook(() => useAudioPlayer());
    const setStateCall = (useAudioPlayerStore.setState as unknown as jest.Mock)
      .mock.calls[0][0];

    setStateCall.setSpeed(1.5);
    expect(mockAudioManager.setSpeed).toHaveBeenCalledWith(1.5);
  });

  it("should override skipForward action to use audio manager", () => {
    renderHook(() => useAudioPlayer());
    const setStateCall = (useAudioPlayerStore.setState as unknown as jest.Mock)
      .mock.calls[0][0];

    setStateCall.skipForward(30);
    expect(mockAudioManager.skipForward).toHaveBeenCalledWith(30);
  });

  it("should override skipBackward action to use audio manager", () => {
    renderHook(() => useAudioPlayer());
    const setStateCall = (useAudioPlayerStore.setState as unknown as jest.Mock)
      .mock.calls[0][0];

    setStateCall.skipBackward(15);
    expect(mockAudioManager.skipBackward).toHaveBeenCalledWith(15);
  });

  it("should override stop action to use audio manager", () => {
    renderHook(() => useAudioPlayer());
    const setStateCall = (useAudioPlayerStore.setState as unknown as jest.Mock)
      .mock.calls[0][0];

    setStateCall.stop();
    expect(mockAudioManager.stop).toHaveBeenCalled();
  });
});
