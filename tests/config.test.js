import { describe, it } from 'node:test';
import assert from 'node:assert';
import { LANGUAGES, CATEGORIES, VOICE_CONFIG } from '../config/languages.js';
import { SOCIAL_PLATFORMS, SOCIAL_LANGUAGES, getSupportedPlatforms, isLanguageEnabled } from '../config/social-media.js';

describe('Configuration', () => {
  
  it('should have valid language configuration', () => {
    assert(Array.isArray(LANGUAGES.SUPPORTED));
    assert(typeof LANGUAGES.PRIMARY === 'string');
    assert(LANGUAGES.SUPPORTED.includes(LANGUAGES.PRIMARY));
    
    // All supported languages should have voice config
    LANGUAGES.SUPPORTED.forEach(lang => {
      assert(VOICE_CONFIG[lang], `Missing voice config for ${lang}`);
      assert(VOICE_CONFIG[lang].languageCode, `Missing languageCode for ${lang}`);
      assert(VOICE_CONFIG[lang].name, `Missing voice name for ${lang}`);
    });
  });

  it('should have valid category configuration', () => {
    assert(Array.isArray(CATEGORIES));
    assert(CATEGORIES.length > 0);
    
    const expectedCategories = ['daily-news', 'ethereum', 'macro'];
    expectedCategories.forEach(cat => {
      assert(CATEGORIES.includes(cat), `Missing category: ${cat}`);
    });
  });

  it('should have valid social media configuration', () => {
    // Check platform configs
    Object.values(SOCIAL_PLATFORMS).forEach(platform => {
      assert(typeof platform.maxLength === 'number');
      assert(typeof platform.style === 'string');
      assert(typeof platform.emoji === 'boolean');
    });

    // Check language configs
    Object.entries(SOCIAL_LANGUAGES).forEach(([lang, config]) => {
      assert(typeof config.enabled === 'boolean');
      assert(Array.isArray(config.platforms));
      assert(typeof config.defaultPlatform === 'string');
      
      if (config.enabled) {
        assert(config.platforms.length > 0, `Enabled language ${lang} has no platforms`);
      }
    });
  });

  it('should have consistent platform references', () => {
    const platformNames = Object.keys(SOCIAL_PLATFORMS);
    
    Object.entries(SOCIAL_LANGUAGES).forEach(([lang, config]) => {
      config.platforms.forEach(platform => {
        assert(platformNames.includes(platform), 
          `Language ${lang} references unknown platform: ${platform}`);
      });
      
      assert(platformNames.includes(config.defaultPlatform),
        `Language ${lang} has unknown default platform: ${config.defaultPlatform}`);
    });
  });

  it('should provide correct helper functions', () => {
    // Test getSupportedPlatforms
    const enPlatforms = getSupportedPlatforms('en-US');
    const jaPlatforms = getSupportedPlatforms('ja-JP');
    const unknownPlatforms = getSupportedPlatforms('unknown');
    
    assert(Array.isArray(enPlatforms));
    assert(Array.isArray(jaPlatforms));
    assert(Array.isArray(unknownPlatforms));
    assert(unknownPlatforms.length === 0);

    // Test isLanguageEnabled
    assert(isLanguageEnabled('en-US') === true);
    assert(isLanguageEnabled('unknown') === false);
  });
});