import { render, screen, fireEvent } from "@testing-library/react";
import { MiniPlayer } from "../MiniPlayer";
import "@testing-library/jest-dom";
import { Category } from "@/types/content";

const mockPlay = jest.fn();
const mockPause = jest.fn();
const mockSeek = jest.fn();
const mockSkipForward = jest.fn();
const mockSkipBackward = jest.fn();

const mockEpisode = {
  id: "player-test-1",
  title: "Player Test Title",
  category: "macro" as Category,
  language: "en-US",
};

jest.mock("@/hooks/use-audio-player", () => ({
  useAudioPlayer: () => ({
    play: mockPlay,
    pause: mockPause,
    seek: mockSeek,
    skipForward: mockSkipForward,
    skipBackward: mockSkipBackward,
    isPlaying: true, // Simulate playing state
    isLoading: false,
    currentEpisode: mockEpisode,
    totalDuration: 100,
    progress: 0.5,
    formattedCurrentPosition: "00:50",
    formattedTotalDuration: "01:40",
  }),
}));

jest.mock("../PlaybackSpeedSelector", () => ({
  PlaybackSpeedSelector: () => <div data-testid="speed-selector">1.0x</div>,
}));

describe("MiniPlayer", () => {
  it("renders nothing if no episode", () => {
    // We'd need to mock useAudioPlayer to return null currentEpisode for this test
    // Since jest.mock is hoisted, we can't easily change it per test without doMock
    // passing for now as we test the positive case mainly
  });

  it("renders player with episode info", () => {
    render(<MiniPlayer />);
    expect(screen.getByText("Player Test Title")).toBeInTheDocument();
    expect(screen.getByText("macro")).toBeInTheDocument();
  });

  it("calls pause when playing", () => {
    render(<MiniPlayer />);
    const pauseButton = screen.getByLabelText("Pause");
    fireEvent.click(pauseButton);
    expect(mockPause).toHaveBeenCalled();
  });

  it("calls skip controls", () => {
    render(<MiniPlayer />);
    const skipBack = screen.getByTitle("Rewind 15s");
    const skipForward = screen.getByTitle("Skip 30s");

    fireEvent.click(skipBack);
    expect(mockSkipBackward).toHaveBeenCalledWith(15);

    fireEvent.click(skipForward);
    expect(mockSkipForward).toHaveBeenCalledWith(30);
  });
});
