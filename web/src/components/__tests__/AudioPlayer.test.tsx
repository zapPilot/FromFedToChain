import { render, screen, fireEvent, act } from "@testing-library/react";
import AudioPlayer from "../AudioPlayer";
import { Episode } from "@/types/content";

describe("AudioPlayer", () => {
  const mockEpisode: Episode = {
    id: "1",
    title: "Test Episode",
    description: "Test Description",
    date: "2024-01-01",
    duration: 120, // 2 minutes
    audioUrl: "https://example.com/audio.mp3",
    streaming_urls: { m3u8: "https://example.com/audio.mp3" },
    language: "en-US",
    category: "daily-news",
  };

  beforeEach(() => {
    // Mock HTMLMediaElement properties and methods
    Object.defineProperty(global.window.HTMLMediaElement.prototype, "play", {
      configurable: true,
      value: jest.fn().mockImplementation(() => Promise.resolve()),
    });
    Object.defineProperty(global.window.HTMLMediaElement.prototype, "pause", {
      configurable: true,
      value: jest.fn(),
    });
    // Default duration
    Object.defineProperty(
      global.window.HTMLMediaElement.prototype,
      "duration",
      {
        configurable: true,
        value: 120, // Match mock episode duration
      },
    );
  });

  it("should render audio player elements", () => {
    render(<AudioPlayer episode={mockEpisode} />);

    // Check for play button
    expect(screen.getByLabelText("Play")).toBeInTheDocument();

    // Check for seek slider
    expect(screen.getByRole("slider")).toBeInTheDocument();

    // Check for time display (initial 0:00). Use queryAllByText because there might be multiple "0:00" if duration starts at 0
    // But we mocked duration to 120, so 120s = 2:00.
    // Trigger loadedmetadata to update duration state
    const audio = document.querySelector("audio");
    fireEvent.loadedMetadata(audio!);

    expect(screen.getByText("0:00")).toBeInTheDocument();
    expect(screen.getByText("2:00")).toBeInTheDocument();
  });

  it("should toggle play/pause", () => {
    render(<AudioPlayer episode={mockEpisode} />);

    const playButton = screen.getByLabelText("Play");

    // Click play
    fireEvent.click(playButton);
    expect(global.window.HTMLMediaElement.prototype.play).toHaveBeenCalled();
    expect(screen.getByLabelText("Pause")).toBeInTheDocument();

    // Click pause
    fireEvent.click(playButton);
    expect(global.window.HTMLMediaElement.prototype.pause).toHaveBeenCalled();
    expect(screen.getByLabelText("Play")).toBeInTheDocument();
  });

  it("should update time on seek", () => {
    render(<AudioPlayer episode={mockEpisode} />);

    // Trigger metadata load to set duration
    const audio = document.querySelector("audio");
    fireEvent.loadedMetadata(audio!);

    const slider = screen.getByRole("slider") as HTMLInputElement;
    fireEvent.change(slider, { target: { value: "30" } });

    expect(slider.value).toBe("30");
    // "0:30" should be displayed
    expect(screen.getByText("0:30")).toBeInTheDocument();
  });
});
