import { render, screen, fireEvent } from "@testing-library/react";
import { EpisodeCard } from "../EpisodeCard";
import "@testing-library/jest-dom";

// Define mock functions
const mockPlay = jest.fn();
const mockPause = jest.fn();

// Default mock values
const defaultMockValues = {
  isPlaying: false,
  currentEpisode: null as any,
};

let mockValues = { ...defaultMockValues };

jest.mock("@/hooks/use-audio-player", () => ({
  useAudioPlayer: () => ({
    play: mockPlay,
    pause: mockPause,
    ...mockValues,
  }),
}));

jest.mock("@/hooks/use-progress", () => ({
  useProgress: () => ({
    progress: { progress: 0.5 },
  }),
}));

const mockEpisode = {
  id: "test-card-1",
  title: "Card Test Title",
  description: "Card Test Description",
  category: "ethereum",
  date: "2024-02-01",
  language: "en-US",
  duration: 300,
  audioUrl: "http://example.com/audio.mp3",
} as any;

describe("EpisodeCard", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockValues = { ...defaultMockValues };
  });

  it("renders episode info", () => {
    render(<EpisodeCard episode={mockEpisode} />);
    expect(screen.getByText("Card Test Title")).toBeInTheDocument();
    expect(screen.getByText("Card Test Description")).toBeInTheDocument();
    expect(screen.getByText("Ethereum")).toBeInTheDocument();
  });

  it("calls play on click when not playing", () => {
    render(<EpisodeCard episode={mockEpisode} />);
    // Play button specific click
    const playButton = screen.getByLabelText("Play");
    fireEvent.click(playButton);
    expect(mockPlay).toHaveBeenCalledWith(mockEpisode);
  });

  it("calls play on card click", () => {
    render(<EpisodeCard episode={mockEpisode} />);
    const card = screen.getByRole("article");
    fireEvent.click(card);
    expect(mockPlay).toHaveBeenCalledWith(mockEpisode);
  });

  it("calls pause when playing this episode", () => {
    mockValues = {
      isPlaying: true,
      currentEpisode: mockEpisode,
    };

    render(<EpisodeCard episode={mockEpisode} />);

    // Check for pause button
    const pauseButton = screen.getByLabelText("Pause");
    expect(pauseButton).toBeInTheDocument();

    // Click it
    fireEvent.click(pauseButton);
    expect(mockPause).toHaveBeenCalled();
  });
});
