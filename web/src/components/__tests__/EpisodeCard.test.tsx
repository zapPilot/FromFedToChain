import { render, screen, fireEvent } from "@testing-library/react";
import { EpisodeCard } from "../EpisodeCard";
import "@testing-library/jest-dom";

const mockPlay = jest.fn();
const mockPause = jest.fn();

jest.mock("@/hooks/use-audio-player", () => ({
  useAudioPlayer: () => ({
    play: mockPlay,
    pause: mockPause,
    isPlaying: false,
    currentEpisode: null,
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
  it("renders episode info", () => {
    render(<EpisodeCard episode={mockEpisode} />);
    expect(screen.getByText("Card Test Title")).toBeInTheDocument();
    expect(screen.getByText("Card Test Description")).toBeInTheDocument();
    expect(screen.getByText("Ethereum")).toBeInTheDocument();
  });

  it("calls play on click", () => {
    render(<EpisodeCard episode={mockEpisode} />);
    const card = screen.getByRole("article");
    fireEvent.click(card);
    expect(mockPlay).toHaveBeenCalledWith(mockEpisode);
  });
});
