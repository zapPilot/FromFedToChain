import { render, screen, fireEvent } from "@testing-library/react";
import { MiniPlayer } from "../MiniPlayer";
import "@testing-library/jest-dom";
import { Category } from "@/types/content";

// Define mock functions
const mockPlay = jest.fn();
const mockPause = jest.fn();
const mockSeek = jest.fn();
const mockSkipForward = jest.fn();
const mockSkipBackward = jest.fn();

// Default values
const defaultMockValues = {
  currentEpisode: {
    id: "player-test-1",
    title: "Player Test Title",
    category: "macro" as Category,
    language: "en-US",
  },
  isPlaying: true,
  isLoading: false,
  totalDuration: 100,
  progress: 0.5,
  formattedCurrentPosition: "00:50",
  formattedTotalDuration: "01:40",
};

// Mutable mock state
let mockValues = { ...defaultMockValues };

jest.mock("@/hooks/use-audio-player", () => ({
  useAudioPlayer: () => ({
    play: mockPlay,
    pause: mockPause,
    seek: mockSeek,
    skipForward: mockSkipForward,
    skipBackward: mockSkipBackward,
    ...mockValues,
  }),
}));

jest.mock("../PlaybackSpeedSelector", () => ({
  PlaybackSpeedSelector: () => <div data-testid="speed-selector">1.0x</div>,
}));

describe("MiniPlayer", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockValues = { ...defaultMockValues };
  });

  it("renders nothing if no episode", () => {
    mockValues = { ...defaultMockValues, currentEpisode: null as any };
    const { container } = render(<MiniPlayer />);
    expect(container).toBeEmptyDOMElement();
  });

  it("renders player with episode info", () => {
    render(<MiniPlayer />);
    expect(screen.getByText("Player Test Title")).toBeInTheDocument();
    expect(screen.getByText("macro")).toBeInTheDocument();
  });

  it("calls pause when playing", () => {
    mockValues = { ...defaultMockValues, isPlaying: true };
    render(<MiniPlayer />);
    const pauseButton = screen.getByLabelText("Pause");
    fireEvent.click(pauseButton);
    expect(mockPause).toHaveBeenCalled();
  });

  it("calls play when paused", () => {
    mockValues = { ...defaultMockValues, isPlaying: false };
    render(<MiniPlayer />);
    const playButton = screen.getByLabelText("Play");
    fireEvent.click(playButton);
    expect(mockPlay).toHaveBeenCalled();
  });

  it("shows loading state", () => {
    mockValues = { ...defaultMockValues, isLoading: true };
    render(<MiniPlayer />);
    // Check for pause button being disabled or showing loading icon
    // The component disables the button when loading
    const button = screen.getByRole("button", { name: /pause/i });
    expect(button).toBeDisabled();
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

  it("seeks when clicking progress bar", () => {
    render(<MiniPlayer />);
    // We need to mock getBoundingClientRect since jsdom doesn't support layout
    const progressBar = screen
      .getByText("Player Test Title")
      .closest(".fixed")
      ?.querySelector(".cursor-pointer") as HTMLElement;

    // Mock getBoundingClientRect
    jest.spyOn(progressBar, "getBoundingClientRect").mockImplementation(() => ({
      width: 100,
      left: 0,
      height: 10,
      top: 0,
      right: 100,
      bottom: 10,
      x: 0,
      y: 0,
      toJSON: () => {},
    }));

    fireEvent.click(progressBar, { clientX: 50 });
    // clientX 50 on width 100 = 50%
    // totalDuration 100 * 0.5 = 50
    expect(mockSeek).toHaveBeenCalledWith(50);
  });
});
