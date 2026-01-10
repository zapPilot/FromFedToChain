import type { Episode } from "@/types/content";
import { EpisodeCard } from "./EpisodeCard";
import { LoadingSkeleton } from "./LoadingSkeleton";
import { ErrorState, EmptyState } from "./ErrorState";

interface EpisodeListProps {
  episodes: Episode[];
  isLoading: boolean;
  error: string | null;
  onRetry?: () => void;
}

/**
 * Episode list component with grid layout
 * Displays episodes in responsive grid with loading/error/empty states
 */
export function EpisodeList({
  episodes,
  isLoading,
  error,
  onRetry,
}: EpisodeListProps) {
  // Loading state
  if (isLoading) {
    return <LoadingSkeleton />;
  }

  // Error state
  if (error) {
    return <ErrorState message={error} onRetry={onRetry} />;
  }

  // Empty state
  if (episodes.length === 0) {
    return (
      <EmptyState
        message="Try adjusting your filters or check back later for new content."
        action={
          onRetry
            ? {
                label: "Reload Episodes",
                onClick: onRetry,
              }
            : undefined
        }
      />
    );
  }

  // Episode grid
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {episodes.map((episode) => (
        <EpisodeCard key={episode.id} episode={episode} />
      ))}
    </div>
  );
}
