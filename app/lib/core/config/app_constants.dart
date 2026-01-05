/// Application-wide constants for the From Fed to Chain app.
///
/// Centralizes magic numbers and configurable values to improve
/// maintainability and make tuning easier.
class AppConstants {
  // Accessibility
  /// Minimum tap target size for accessibility compliance (48dp).
  static const double minTapTargetSize = 48.0;

  // Audio Progress
  /// Throttle interval for progress updates in milliseconds.
  static const int progressUpdateThrottleMs = 1000;

  /// Time to wait before autoplay transition in milliseconds.
  static const int autoplayTransitionDelayMs = 500;

  /// Threshold percentage to consider an episode "completed" (e.g., 0.95 = 95%).
  static const double completionThreshold = 0.95;

  /// Time in seconds to skip back from end for resume position.
  static const int resumeRewindSeconds = 5;

  // Network
  /// Maximum retry attempts for failed network requests.
  static const int maxNetworkRetries = 3;

  /// Base retry delay in seconds (multiplied by attempt number).
  static const int retryDelaySeconds = 1;

  // Cache
  /// Cache expiration time in hours for episode data.
  static const int cacheExpirationHours = 24;

  // UI
  /// Default animation duration for micro-interactions.
  static const int animationDurationMs = 300;

  /// Mini player height in logical pixels.
  static const double miniPlayerHeight = 72.0;

  /// Bottom navigation bar height in logical pixels.
  static const double bottomNavHeight = 56.0;
}
