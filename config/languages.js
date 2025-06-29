export const LANGUAGES = {
  PRIMARY: 'zh-TW',
  SUPPORTED: ['zh-TW', 'en-US', 'ja-JP']
};

export const CATEGORIES = ['daily-news', 'ethereum', 'macro'];

export const PATHS = {
  CONTENT_ROOT: './content',
  AUDIO_ROOT: './audio',
  SERVICE_ACCOUNT: './service-account.json'
};

export const VOICE_CONFIG = {
  'zh-TW': {
    languageCode: "zh-TW",
    name: "cmn-TW-Wavenet-B"
  },
  'en-US': {
    languageCode: "en-US",
    name: "en-US-Wavenet-D",
    socialPrefix: "🚀",
    hookLength: 150
  },
  'ja-JP': {
    languageCode: "ja-JP",
    name: "ja-JP-Wavenet-C"
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