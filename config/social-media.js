// Social Media Configuration for FromFedToChain
export const SOCIAL_PLATFORMS = {
  twitter: {
    name: 'Twitter',
    maxLength: 280,
    threadSupport: true,
    threadIndicator: '🧵',
    style: 'punchy',
    emoji: true,
    hashtags: true,
    maxHashtags: 3,
  },
  linkedin: {
    name: 'LinkedIn',
    maxLength: 3000,
    threadSupport: false,
    style: 'professional',
    emoji: false,
    hashtags: true,
    maxHashtags: 5,
  },
  facebook: {
    name: 'Facebook',
    maxLength: 63206,
    threadSupport: false,
    style: 'conversational',
    emoji: true,
    hashtags: false,
    maxHashtags: 0,
  },
  instagram: {
    name: 'Instagram',
    maxLength: 2200,
    threadSupport: false,
    style: 'visual',
    emoji: true,
    hashtags: true,
    maxHashtags: 10,
  },
};

// Language-specific social media preferences
export const SOCIAL_LANGUAGES = {
  'zh-TW': {
    enabled: true,
    platforms: ['twitter', 'facebook', 'instagram'],
    defaultPlatform: 'twitter',
    hashtags: {
      'daily-news': ['#加密貨幣', '#比特幣', '#區塊鏈'],
      'ethereum': ['#以太坊', '#DeFi', '#區塊鏈'],
      'macro': ['#金融', '#經濟', '#投資'],
    },
  },
  'en-US': {
    enabled: true,
    platforms: ['twitter', 'linkedin', 'facebook', 'instagram'],
    defaultPlatform: 'twitter',
    hashtags: {
      'daily-news': ['#Crypto', '#Bitcoin', '#Blockchain'],
      'ethereum': ['#Ethereum', '#DeFi', '#Web3'],
      'macro': ['#Finance', '#Economics', '#Investment'],
    },
  },
  'ja-JP': {
    enabled: true,
    platforms: ['twitter', 'facebook'],
    defaultPlatform: 'twitter',
    hashtags: {
      'daily-news': ['#暗号資産', '#ビットコイン', '#ブロックチェーン'],
      'ethereum': ['#イーサリアム', '#DeFi', '#Web3'],
      'macro': ['#金融', '#経済', '#投資'],
    },
  },
};

// Category-specific configurations
export const CATEGORY_CONFIG = {
  'daily-news': {
    priority: 'high',
    urgency: true,
    keywordBoosts: ['government', 'breakthrough', 'regulation', 'adoption'],
  },
  'ethereum': {
    priority: 'medium',
    urgency: false,
    keywordBoosts: ['upgrade', 'scaling', 'DeFi', 'staking'],
  },
  'macro': {
    priority: 'medium',
    urgency: false,
    keywordBoosts: ['policy', 'inflation', 'banking', 'economy'],
  },
};

// Output configuration
export const OUTPUT_CONFIG = {
  // File structure: social/{language}/{platform}/{category}/
  outputStructure: 'social/{{language}}/{{platform}}/{{category}}/',
  fileExtension: '.txt',
  metadataExtension: '.json',
  includeMetadata: true,
};

// Helper functions
export function getSupportedPlatforms(language) {
  return SOCIAL_LANGUAGES[language]?.platforms || [];
}

export function getDefaultPlatform(language) {
  return SOCIAL_LANGUAGES[language]?.defaultPlatform || 'twitter';
}

export function getHashtagsForCategory(language, category) {
  return SOCIAL_LANGUAGES[language]?.hashtags?.[category] || [];
}

export function isLanguageEnabled(language) {
  return SOCIAL_LANGUAGES[language]?.enabled || false;
}

export function getEnabledLanguages() {
  return Object.keys(SOCIAL_LANGUAGES).filter(lang => SOCIAL_LANGUAGES[lang].enabled);
}

export function getPlatformConfig(platform) {
  return SOCIAL_PLATFORMS[platform] || SOCIAL_PLATFORMS.twitter;
}

export function getCategoryConfig(category) {
  return CATEGORY_CONFIG[category] || CATEGORY_CONFIG['daily-news'];
}