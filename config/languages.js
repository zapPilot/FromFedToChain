export const LANGUAGES = {
  PRIMARY: 'zh-TW',
  SUPPORTED: ['zh-TW', 'en-US', 'ja-JP']
};

export const CATEGORIES = ['daily-news', 'ethereum', 'macro'];

export const PATHS = {
  CONTENT_ROOT: './content',
  SERVICE_ACCOUNT: './service-account.json'
};

export const VOICE_CONFIG = {
  'zh-TW': {
    languageCode: "zh-TW",
    name: "cmn-TW-Wavenet-B",
    folderId: "14AhPDY0WCrL6G_W6ZZ6cfR01znf0WLKF"
  },
  'en-US': {
    languageCode: "en-US",
    name: "en-US-Wavenet-D",
    folderId: "1MkzZPY2iu09smRAwzGwXXG5_-hUDCVLw",
    socialPrefix: "🚀",
    hookLength: 150
  },
  'ja-JP': {
    languageCode: "ja-JP",
    name: "ja-JP-Wavenet-C",
    folderId: "1KJ1WHnnFtsafzsrWuK6S3S8Atym5lVDs"
  }
};

export const TRANSLATION_CONFIG = {
  'en-US': {
    voice: VOICE_CONFIG['en-US']
  }
};