// ============================================
// UNIFIED LANGUAGE CONFIGURATION
// Single source of truth for all language settings
// ============================================

export const LANGUAGE_CONFIG = {
  // Source language (Traditional Chinese)
  "zh-TW": {
    name: "Traditional Chinese",
    region: "Taiwan",
    isSource: true,
    isTarget: false,

    // Google Cloud TTS Configuration
    tts: {
      languageCode: "zh-TW",
      voiceName: "cmn-TW-Wavenet-B",
      gender: "FEMALE",
      speakingRate: 1.0,
      pitch: 0.0,
    },

    // Translation API mapping (for content coming FROM this language)
    translationCode: "zh",

    // Social media settings
    social: {
      prefix: "📰",
      hookLength: 180, // Chinese can be more concise
      platforms: ["twitter", "threads", "farcaster", "debank"],
    },

    // Content processing
    contentProcessing: {
      generateAudio: true, // Generate TTS for source language too!
      generateSocialHooks: true,
      requiresTranslation: false,
    },
  },

  // English (US)
  "en-US": {
    name: "English",
    region: "United States",
    isSource: false,
    isTarget: true,

    // Google Cloud TTS Configuration
    tts: {
      languageCode: "en-US",
      voiceName: "en-US-Wavenet-D",
      gender: "MALE",
      speakingRate: 1.0,
      pitch: 0.0,
    },

    // Translation API mapping (for content going TO this language)
    translationCode: "en",

    // Social media settings
    social: {
      prefix: "🚀",
      hookLength: 150, // Twitter-optimized
      platforms: ["twitter", "threads", "farcaster", "debank"],
    },

    // Content processing
    contentProcessing: {
      generateAudio: true,
      generateSocialHooks: true,
      requiresTranslation: true,
    },
  },

  // Japanese
  "ja-JP": {
    name: "Japanese",
    region: "Japan",
    isSource: false,
    isTarget: true,

    // Google Cloud TTS Configuration
    tts: {
      languageCode: "ja-JP",
      voiceName: "ja-JP-Wavenet-C",
      gender: "FEMALE",
      speakingRate: 1.0,
      pitch: 0.0,
    },

    // Translation API mapping
    translationCode: "ja",

    // Social media settings
    social: {
      prefix: "🌸",
      hookLength: 140, // Japanese can be very concise
      platforms: ["twitter", "threads"],
    },

    // Content processing
    contentProcessing: {
      generateAudio: true,
      generateSocialHooks: true,
      requiresTranslation: true,
    },
  },
};

// ============================================
// DERIVED CONFIGURATIONS
// ============================================

// Basic language lists
export const LANGUAGES = {
  PRIMARY: "zh-TW",
  SUPPORTED: Object.keys(LANGUAGE_CONFIG),
  TRANSLATION_TARGETS: Object.keys(LANGUAGE_CONFIG).filter(
    (lang) => LANGUAGE_CONFIG[lang].isTarget,
  ),
};

// Content categories
export const CATEGORIES = ["daily-news", "ethereum", "macro"];

// File system paths
export const PATHS = {
  CONTENT_ROOT: "./content",
  AUDIO_ROOT: "./audio",
  SERVICE_ACCOUNT: "./service-account.json",
};

// ============================================
// HELPER FUNCTIONS
// ============================================

// Get all languages that should have audio generated
export const getAudioLanguages = () => {
  return Object.keys(LANGUAGE_CONFIG).filter(
    (lang) => LANGUAGE_CONFIG[lang].contentProcessing.generateAudio,
  );
};

// Get translation target languages (excluding source)
export const getTranslationTargets = () => {
  return LANGUAGES.TRANSLATION_TARGETS;
};

// Get TTS configuration for a language
export const getTTSConfig = (language) => {
  const config = LANGUAGE_CONFIG[language];
  if (!config) {
    throw new Error(`Unsupported language: ${language}`);
  }

  return {
    languageCode: config.tts.languageCode,
    name: config.tts.voiceName,
    voiceConfig: {
      languageCode: config.tts.languageCode,
      name: config.tts.voiceName,
      ssmlGender: config.tts.gender,
    },
    audioConfig: {
      audioEncoding: "LINEAR16",
      sampleRateHertz: 16000,
      speakingRate: config.tts.speakingRate,
      pitch: config.tts.pitch,
    },
  };
};

// Get translation configuration for a language
export const getTranslationConfig = (language) => {
  const config = LANGUAGE_CONFIG[language];
  if (!config) {
    throw new Error(`Unsupported language: ${language}`);
  }

  return {
    languageCode: config.translationCode,
    targetLanguage: language,
    isTarget: config.isTarget,
  };
};

// Get social media configuration for a language
export const getSocialConfig = (language) => {
  const config = LANGUAGE_CONFIG[language];
  if (!config) {
    throw new Error(`Unsupported language: ${language}`);
  }

  return config.social;
};

// Check if language should have audio generated
export const shouldGenerateAudio = (language) => {
  return LANGUAGE_CONFIG[language]?.contentProcessing?.generateAudio || false;
};

// Check if language should have social hooks generated
export const shouldGenerateSocialHooks = (language) => {
  return (
    LANGUAGE_CONFIG[language]?.contentProcessing?.generateSocialHooks || false
  );
};

// Get language display name
export const getLanguageName = (language) => {
  return LANGUAGE_CONFIG[language]?.name || language;
};

// ============================================
// BACKWARD COMPATIBILITY (DEPRECATED)
// ============================================

// Legacy exports for backward compatibility - mark as deprecated
export const VOICE_CONFIG = Object.fromEntries(
  Object.entries(LANGUAGE_CONFIG).map(([lang, config]) => [
    lang,
    {
      languageCode: config.tts.languageCode,
      name: config.tts.voiceName,
    },
  ]),
);

export const TRANSLATION_CONFIG = Object.fromEntries(
  LANGUAGES.TRANSLATION_TARGETS.map((lang) => [
    lang,
    {
      voice: VOICE_CONFIG[lang],
    },
  ]),
);

// Deprecated - use getTranslationTargets() instead
export const getTargetLanguages = () => {
  console.warn(
    "getTargetLanguages() is deprecated. Use getTranslationTargets() instead.",
  );
  return getTranslationTargets();
};

// ============================================
// VALIDATION
// ============================================

// Validate language configuration at startup
export const validateLanguageConfig = () => {
  const errors = [];

  Object.entries(LANGUAGE_CONFIG).forEach(([lang, config]) => {
    if (!config.name) errors.push(`${lang}: Missing name`);
    if (!config.tts?.languageCode)
      errors.push(`${lang}: Missing TTS languageCode`);
    if (!config.tts?.voiceName) errors.push(`${lang}: Missing TTS voiceName`);
    if (!config.translationCode)
      errors.push(`${lang}: Missing translationCode`);
    if (!config.social?.hookLength)
      errors.push(`${lang}: Missing social hookLength`);
  });

  if (errors.length > 0) {
    throw new Error(`Language configuration errors:\n${errors.join("\n")}`);
  }

  return true;
};

// Validate on module load
validateLanguageConfig();
