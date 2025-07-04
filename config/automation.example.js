// Example automation configuration
// Copy this to automation.js and fill in your credentials

export const AUTOMATION_CONFIG = {
  spotify: {
    // You'll need to log in manually via browser automation
    // Spotify for Podcasters doesn't have a public API for uploads
    email: process.env.SPOTIFY_EMAIL || "your-spotify-email@example.com",
    password: process.env.SPOTIFY_PASSWORD || "your-password",

    // Your podcast show settings
    showSettings: {
      category: "Technology",
      language: "English", // Primary language
      explicit: false,
    },
  },

  social: {
    // Social platforms will require manual login via browser automation
    // Consider setting up accounts for:
    platforms: [
      "twitter", // X/Twitter
      "threads", // Meta Threads
      "farcaster", // Farcaster via Warpcast
      "debank", // DeBank (requires wallet connection)
    ],

    // Platform-specific settings
    twitter: {
      maxLength: 280,
      includeHashtags: true,
    },

    threads: {
      maxLength: 500,
      includeHashtags: true,
    },

    farcaster: {
      maxLength: 320,
      includeHashtags: false, // Farcaster doesn't use hashtags much
    },

    debank: {
      maxLength: 1000,
      includeHashtags: true,
    },
  },

  // Browser automation settings
  browser: {
    headless: false, // Keep visible for manual auth
    slowMo: 1000, // Slow down for reliability
    timeout: 300000, // 5 minute timeout for uploads
    retryAttempts: 3, // Retry failed operations
    delayBetweenPosts: 2000, // 2 second delay between social posts
  },
};

// Environment-specific overrides
if (process.env.NODE_ENV === "production") {
  AUTOMATION_CONFIG.browser.headless = true;
  AUTOMATION_CONFIG.browser.slowMo = 500;
}
