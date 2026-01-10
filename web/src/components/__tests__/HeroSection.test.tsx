import { render, screen, fireEvent } from "@testing-library/react";
import { HeroSection } from "../HeroSection";
// import "@testing-library/jest-dom"; // Already in setup

// Mock hooks
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

const mockEpisode = {
  id: "test-episode-1",
  title: "Test Episode Title",
  description: "Test description",
  category: "daily-news",
  date: "2024-01-01",
  language: "en-US",
  duration: 120,
  audioUrl: "http://example.com/audio.mp3",
} as any;

describe("HeroSection", () => {
  it("renders nothing if no episode provided", () => {
    const { container } = render(<HeroSection episode={undefined} />);
    expect(container).toBeEmptyDOMElement();
  });

  it("renders loading skeleton when loading", () => {
    render(<HeroSection episode={mockEpisode} isLoading={true} />);
    // Using a class based check usually, but here we can check if the title is NOT present yet
    // or check for the animate-pulse class if possible, but testing library prefers accessible queries.
    // The skeleton has no text, so we can check that title is NOT there.
    expect(screen.queryByText("Test Episode Title")).not.toBeInTheDocument();
  });

  it("renders episode details when provided", () => {
    render(<HeroSection episode={mockEpisode} />);
    expect(screen.getByText("Test Episode Title")).toBeInTheDocument();
    expect(screen.getByText("Test description")).toBeInTheDocument();
    expect(screen.getByText("Featured • Daily News")).toBeInTheDocument();
  });

  it("calls play when play button clicked", () => {
    render(<HeroSection episode={mockEpisode} />);
    const playButton = screen.getByRole("button", { name: /play briefing/i });
    fireEvent.click(playButton);
    expect(mockPlay).toHaveBeenCalledWith(mockEpisode);
  });
});
