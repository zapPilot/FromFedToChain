import { describe, it } from 'node:test';
import assert from 'node:assert';
import { LANGUAGES, CATEGORIES, VOICE_CONFIG } from '../config/languages.js';

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

  it('should support social media languages', () => {
    // Test simplified social media support
    const socialLanguages = ['en-US', 'ja-JP'];
    
    socialLanguages.forEach(lang => {
      assert(LANGUAGES.SUPPORTED.includes(lang), `Social language ${lang} not in supported languages`);
      assert(VOICE_CONFIG[lang], `Social language ${lang} missing voice config`);
    });
  });
});