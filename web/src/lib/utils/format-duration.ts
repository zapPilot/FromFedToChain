/**
 * Format duration in seconds to human-readable format
 *
 * @param seconds - Duration in seconds
 * @param alwaysShowHours - Always show hours even if zero
 * @returns Formatted duration string (MM:SS or HH:MM:SS)
 *
 * @example
 * formatDuration(65) // "01:05"
 * formatDuration(3665) // "1:01:05"
 * formatDuration(65, true) // "0:01:05"
 */
export function formatDuration(
  seconds: number,
  alwaysShowHours: boolean = false,
): string {
  if (!isFinite(seconds) || seconds < 0) {
    return "0:00";
  }

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  const pad = (num: number) => String(num).padStart(2, "0");

  if (hours > 0 || alwaysShowHours) {
    return `${hours}:${pad(minutes)}:${pad(secs)}`;
  }

  return `${minutes}:${pad(secs)}`;
}

/**
 * Parse duration string to seconds
 *
 * @param duration - Duration string (MM:SS or HH:MM:SS)
 * @returns Duration in seconds
 *
 * @example
 * parseDuration("01:05") // 65
 * parseDuration("1:01:05") // 3665
 */
export function parseDuration(duration: string): number {
  const parts = duration.split(":").map((part) => parseInt(part, 10));

  if (parts.length === 2) {
    // MM:SS format
    const [minutes, seconds] = parts;
    return minutes * 60 + seconds;
  } else if (parts.length === 3) {
    // HH:MM:SS format
    const [hours, minutes, seconds] = parts;
    return hours * 3600 + minutes * 60 + seconds;
  }

  return 0;
}

/**
 * Format duration for display with units
 *
 * @param seconds - Duration in seconds
 * @returns Formatted duration with units (e.g., "1h 30m", "45m", "30s")
 */
export function formatDurationWithUnits(seconds: number): string {
  if (!isFinite(seconds) || seconds < 0) {
    return "0s";
  }

  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const secs = Math.floor(seconds % 60);

  const parts: string[] = [];

  if (hours > 0) {
    parts.push(`${hours}h`);
  }
  if (minutes > 0) {
    parts.push(`${minutes}m`);
  }
  if (secs > 0 || parts.length === 0) {
    parts.push(`${secs}s`);
  }

  return parts.join(" ");
}
