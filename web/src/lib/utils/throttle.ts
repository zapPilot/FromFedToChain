/**
 * Throttle function to limit execution rate
 * Ensures function is called at most once per specified interval
 *
 * @param func - Function to throttle
 * @param limit - Minimum time between calls in milliseconds
 * @returns Throttled function
 *
 * @example
 * const throttledFn = throttle(() => console.log('Called'), 1000);
 * throttledFn(); // Executes immediately
 * throttledFn(); // Ignored (within 1000ms)
 * setTimeout(() => throttledFn(), 1100); // Executes (after 1000ms)
 */
export function throttle<T extends (...args: unknown[]) => void>(
  func: T,
  limit: number,
): (...args: Parameters<T>) => void {
  let inThrottle: boolean = false;
  let lastResult: ReturnType<T>;

  return function (this: unknown, ...args: Parameters<T>): void {
    if (!inThrottle) {
      // Execute function immediately
      lastResult = func.apply(this, args) as ReturnType<T>;
      inThrottle = true;

      // Reset throttle after limit
      setTimeout(() => {
        inThrottle = false;
      }, limit);
    }
  };
}

/**
 * Debounce function to delay execution until after specified wait time
 * Useful for input handlers, window resize, etc.
 *
 * @param func - Function to debounce
 * @param wait - Wait time in milliseconds
 * @returns Debounced function with cancel method
 *
 * @example
 * const debouncedFn = debounce(() => console.log('Called'), 300);
 * debouncedFn(); // Starts timer
 * debouncedFn(); // Resets timer
 * debouncedFn(); // Resets timer
 * // After 300ms of inactivity: "Called"
 */
export function debounce<T extends (...args: unknown[]) => void>(
  func: T,
  wait: number,
): ((...args: Parameters<T>) => void) & { cancel: () => void } {
  let timeoutId: ReturnType<typeof setTimeout> | null = null;

  const debounced = function (this: unknown, ...args: Parameters<T>): void {
    // Clear existing timeout
    if (timeoutId !== null) {
      clearTimeout(timeoutId);
    }

    // Set new timeout
    timeoutId = setTimeout(() => {
      func.apply(this, args);
      timeoutId = null;
    }, wait);
  };

  // Add cancel method
  debounced.cancel = () => {
    if (timeoutId !== null) {
      clearTimeout(timeoutId);
      timeoutId = null;
    }
  };

  return debounced;
}

/**
 * Create a rate-limited function that batches calls
 * Collects all calls within the limit period and executes once with all arguments
 *
 * @param func - Function to batch
 * @param limit - Time window for batching in milliseconds
 * @returns Batched function
 *
 * @example
 * const batchedFn = batch((items) => console.log('Batch:', items), 1000);
 * batchedFn('a'); // Queued
 * batchedFn('b'); // Queued
 * batchedFn('c'); // Queued
 * // After 1000ms: "Batch: ['a', 'b', 'c']"
 */
export function batch<T>(
  func: (items: T[]) => void,
  limit: number,
): (item: T) => void {
  let queue: T[] = [];
  let timeoutId: ReturnType<typeof setTimeout> | null = null;

  return function (item: T): void {
    queue.push(item);

    if (timeoutId === null) {
      timeoutId = setTimeout(() => {
        func(queue);
        queue = [];
        timeoutId = null;
      }, limit);
    }
  };
}
