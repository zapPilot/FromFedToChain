/**
 * Loading skeleton component with shimmer effect
 * Used to show placeholder while content is loading
 */
export function LoadingSkeleton() {
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 animate-pulse">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="bg-zinc-800 rounded-lg p-6 space-y-4">
          {/* Title skeleton */}
          <div className="h-6 bg-zinc-700 rounded w-3/4" />

          {/* Description skeleton */}
          <div className="space-y-2">
            <div className="h-4 bg-zinc-700 rounded w-full" />
            <div className="h-4 bg-zinc-700 rounded w-5/6" />
          </div>

          {/* Metadata skeleton */}
          <div className="flex items-center gap-2">
            <div className="h-5 w-5 bg-zinc-700 rounded" />
            <div className="h-4 bg-zinc-700 rounded w-20" />
          </div>
        </div>
      ))}
    </div>
  );
}

/**
 * Single card loading skeleton
 */
export function CardSkeleton() {
  return (
    <div className="bg-zinc-800 rounded-lg p-6 space-y-4 animate-pulse">
      <div className="h-6 bg-zinc-700 rounded w-3/4" />
      <div className="space-y-2">
        <div className="h-4 bg-zinc-700 rounded w-full" />
        <div className="h-4 bg-zinc-700 rounded w-5/6" />
      </div>
      <div className="flex items-center gap-2">
        <div className="h-5 w-5 bg-zinc-700 rounded" />
        <div className="h-4 bg-zinc-700 rounded w-20" />
      </div>
    </div>
  );
}
