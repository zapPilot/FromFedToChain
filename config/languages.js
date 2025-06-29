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
    folders: {
      'daily-news': "1qciwI3wj8YGNXUiwGhDwKOIAwDXdZzlI",
      'macro': "1-BUjF3J-ENPQRnPHVByZQ7zOy1OQxXCa",
      "ethereum": "1zjyELljkjx0yX2EmFsdw4lcPXOQnS0Gw"
    }
  },
  'en-US': {
    languageCode: "en-US",
    name: "en-US-Wavenet-D",
    folders: {
      'daily-news': "1DCgCiCm0iyUBwZMtYAqADsG1oT3W2Fei",
      'macro': "1WKFlumPWJ92brvfCkztO7PGw_vEh6f1X",
      "ethereum": "1LyR50isTCTf2NoXz_2FWZTYYindvgaeu"
    },
    socialPrefix: "🚀",
    hookLength: 150
  },
  'ja-JP': {
    languageCode: "ja-JP",
    name: "ja-JP-Wavenet-C",
    folders: {
      'daily-news': "1OSUk7dKM17npIQSXXoKEvgNwDBq9kMoC",
      'macro': "1B1iqOWcaAEXP7gK6iqjri604XXXPlM64",
      "ethereum": "1lv4uxITf-UFnR5GQTz0dabonNKJR9ykX"
    }
  }
};

export const TRANSLATION_CONFIG = {
  'en-US': {
    voice: VOICE_CONFIG['en-US']
  },
  'ja-JP': {
    voice: VOICE_CONFIG['ja-JP']
  }
};

// Helper to get target languages (all except primary)
export const getTargetLanguages = () => {
  return LANGUAGES.SUPPORTED.filter(lang => lang !== LANGUAGES.PRIMARY);
};