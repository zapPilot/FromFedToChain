import { render, screen, fireEvent } from "@testing-library/react";
import { EpisodeList } from "../EpisodeList";
import { Episode } from "@/types/content";

// Mock child components to isolate EpisodeList logic
jest.mock("../EpisodeCard", () => ({
  EpisodeCard: ({ episode }: { episode: Episode }) => (
    <div data-testid="episode-card">{episode.title}</div>
  ),
}));

jest.mock("../LoadingSkeleton", () => ({
  LoadingSkeleton: () => <div data-testid="loading-skeleton">Loading...</div>,
}));

jest.mock("../ErrorState", () => ({
  ErrorState: ({
    message,
    onRetry,
  }: {
    message: string;
    onRetry?: () => void;
  }) => (
    <div data-testid="error-state">
      {message}
      {onRetry && <button onClick={onRetry}>Retry</button>}
    </div>
  ),
  EmptyState: ({
    message,
    action,
  }: {
    message: string;
    action?: { label: string; onClick: () => void };
  }) => (
    <div data-testid="empty-state">
      {message}
      {action && <button onClick={action.onClick}>{action.label}</button>}
    </div>
  ),
}));

describe("EpisodeList", () => {
  const mockEpisodes: Episode[] = [
    {
      id: "1",
      title: "Ep 1",
      date: "2024-01-01",
      duration: 100,
      language: "en-US",
      category: "daily-news",
    },
    {
      id: "2",
      title: "Ep 2",
      date: "2024-01-02",
      duration: 200,
      language: "en-US",
      category: "daily-news",
    },
  ];

  it("should render loading skeleton when isLoading is true", () => {
    render(<EpisodeList episodes={[]} isLoading={true} error={null} />);
    expect(screen.getByTestId("loading-skeleton")).toBeInTheDocument();
  });

  it("should render error state when error is present", () => {
    render(
      <EpisodeList
        episodes={[]}
        isLoading={false}
        error="Something went wrong"
      />,
    );
    expect(screen.getByTestId("error-state")).toHaveTextContent(
      "Something went wrong",
    );
  });

  it("should render empty state when no episodes", () => {
    render(<EpisodeList episodes={[]} isLoading={false} error={null} />);
    expect(screen.getByTestId("empty-state")).toBeInTheDocument();
  });

  it("should render episode cards when episodes exist", () => {
    render(
      <EpisodeList episodes={mockEpisodes} isLoading={false} error={null} />,
    );

    // Should verify two cards are rendered
    const cards = screen.getAllByTestId("episode-card");
    expect(cards).toHaveLength(2);
    expect(cards[0]).toHaveTextContent("Ep 1");
    expect(cards[1]).toHaveTextContent("Ep 2");
  });

  it("should pass onRetry to EmptyState when provided", () => {
    const onRetry = jest.fn();
    render(
      <EpisodeList
        episodes={[]}
        isLoading={false}
        error={null}
        onRetry={onRetry}
      />,
    );

    const reloadButton = screen.getByText("Reload Episodes");
    fireEvent.click(reloadButton);
    expect(onRetry).toHaveBeenCalled();
  });

  it("should pass onRetry to ErrorState when provided", () => {
    const onRetry = jest.fn();
    render(
      <EpisodeList
        episodes={[]}
        isLoading={false}
        error="Error"
        onRetry={onRetry}
      />,
    );

    const retryButton = screen.getByText("Retry");
    fireEvent.click(retryButton);
    expect(onRetry).toHaveBeenCalled();
  });
});
