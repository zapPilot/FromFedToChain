interface ErrorStateProps {
  message: string;
  onRetry?: () => void;
}

/**
 * Error state component with retry button
 * Displays error message and optional retry action
 */
export function ErrorState({ message, onRetry }: ErrorStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4">
      <div className="text-red-500 text-6xl mb-4">⚠️</div>
      <h3 className="text-xl font-semibold text-zinc-100 mb-2">
        Something went wrong
      </h3>
      <p className="text-zinc-400 text-center mb-6 max-w-md">{message}</p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="px-6 py-3 bg-zinc-700 hover:bg-zinc-600 text-zinc-100 rounded-lg transition-colors"
        >
          Try Again
        </button>
      )}
    </div>
  );
}

/**
 * Empty state component
 * Shows when no content is available
 */
interface EmptyStateProps {
  message: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export function EmptyState({ message, action }: EmptyStateProps) {
  return (
    <div className="flex flex-col items-center justify-center py-12 px-4">
      <div className="text-zinc-600 text-6xl mb-4">📭</div>
      <h3 className="text-xl font-semibold text-zinc-100 mb-2">
        No episodes found
      </h3>
      <p className="text-zinc-400 text-center mb-6 max-w-md">{message}</p>
      {action && (
        <button
          onClick={action.onClick}
          className="px-6 py-3 bg-zinc-700 hover:bg-zinc-600 text-zinc-100 rounded-lg transition-colors"
        >
          {action.label}
        </button>
      )}
    </div>
  );
}
