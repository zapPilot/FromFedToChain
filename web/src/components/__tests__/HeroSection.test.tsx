import { render, screen, fireEvent } from "@testing-library/react";
import { HeroSection } from "../HeroSection";
import type { Episode } from "@/types/content";
import "@testing-library/jest-dom";

// Mock hooks
const mockPlay = jest.fn();
const mockPause = jest.fn();

// Default mock values
interface AudioPlayerMockValues {
  isPlaying: boolean;
  currentEpisode: Episode | null;
}

const defaultMockValues: AudioPlayerMockValues = {
  isPlaying: false,
  currentEpisode: null,
};

let mockValues: AudioPlayerMockValues = { ...defaultMockValues };

jest.mock("@/hooks/use-audio-player", () => ({
  useAudioPlayer: () => ({
    play: mockPlay,
    pause: mockPause,
    ...mockValues,
  }),
}));

const mockEpisode: Episode = {
  id: "test-episode-1",
  title: "Test Episode Title",
  description: "Test description",
  category: "daily-news",
  date: "2024-01-01",
  language: "en-US",
  status: "published",
  content: "",
  updated_at: "2024-01-01T00:00:00Z",
  duration: 120,
  streaming_urls: { m3u8: "http://example.com/audio.m3u8" },
};

describe("HeroSection", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockValues = { ...defaultMockValues };
  });

  it("renders nothing if no episode provided", () => {
    const { container } = render(<HeroSection episode={undefined} />);
    expect(container).toBeEmptyDOMElement();
  });

  it("renders loading skeleton when loading", () => {
    render(<HeroSection episode={mockEpisode} isLoading={true} />);
    expect(screen.queryByText("Test Episode Title")).not.toBeInTheDocument();
  });

  it("renders episode details with description", () => {
    render(<HeroSection episode={mockEpisode} />);
    expect(screen.getByText("Test Episode Title")).toBeInTheDocument();
    expect(screen.getByText("Test description")).toBeInTheDocument();
    expect(screen.getByText("Featured • Daily News")).toBeInTheDocument();
  });

  it("renders fallback description if missing", () => {
    const episodeWithoutDesc = { ...mockEpisode, description: "" };
    render(<HeroSection episode={episodeWithoutDesc} />);
    expect(
      screen.getByText(
        "Listen to the latest market intelligence and analysis.",
      ),
    ).toBeInTheDocument();
  });

  it("calls play when play button clicked", () => {
    render(<HeroSection episode={mockEpisode} />);
    const playButton = screen.getByRole("button", { name: /play briefing/i });
    fireEvent.click(playButton);
    expect(mockPlay).toHaveBeenCalledWith(mockEpisode);
  });

  it("calls pause when playing current episode", () => {
    // Set up mock to simulate playing this episode
    mockValues = {
      isPlaying: true,
      currentEpisode: mockEpisode,
    };

    render(<HeroSection episode={mockEpisode} />);

    // Button text should change to "Pause Briefing"
    const pauseButton = screen.getByRole("button", { name: /pause briefing/i });
    expect(pauseButton).toBeInTheDocument();

    fireEvent.click(pauseButton);
    expect(mockPause).toHaveBeenCalled();
  });

  it("calls play when playing DIFFERENT episode", () => {
    // Playing, but a different episode
    mockValues = {
      isPlaying: true,
      currentEpisode: { ...mockEpisode, id: "other-episode" },
    };

    render(<HeroSection episode={mockEpisode} />);

    // Should still show "Play" because it asks to switch to this episode
    const playButton = screen.getByRole("button", { name: /play briefing/i });
    expect(playButton).toBeInTheDocument();

    fireEvent.click(playButton);
    expect(mockPlay).toHaveBeenCalledWith(mockEpisode);
  });
});
