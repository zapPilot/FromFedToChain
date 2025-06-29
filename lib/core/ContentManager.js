import { FileUtils } from '../utils/FileUtils.js';
import { LANGUAGES } from '../../config/languages.js';

export class ContentManager {
  // Get files ready for review (source language, not reviewed)
  static async getFilesForReview() {
    return FileUtils.scanContentFiles(file => {
      return file.language === LANGUAGES.PRIMARY &&
             file.data.metadata?.translation_status?.source_reviewed === false;
    });
  }

  // Get files ready for translation (reviewed, not rejected)
  static async getFilesForTranslation() {
    return FileUtils.scanContentFiles(file => {
      if (file.language !== LANGUAGES.PRIMARY) return false;
      
      const status = file.data.metadata?.translation_status;
      const isReviewed = status?.source_reviewed === true;
      const isRejected = status?.rejection?.rejected === true;
      
      return isReviewed && !isRejected;
    });
  }

  // Get files ready for TTS (translated, pending TTS)
  static async getFilesForTTS() {
    const results = [];
    const files = await FileUtils.scanContentFiles();
    
    for (const file of files) {
      if (!file.data.languages || !file.data.metadata?.tts) continue;
      
      for (const [lang, langData] of Object.entries(file.data.languages)) {
        const ttsStatus = file.data.metadata.tts[lang];
        const translationStatus = file.data.metadata.translation_status;
        
        const isRejected = translationStatus?.rejection?.rejected === true;
        const isReviewed = translationStatus?.source_reviewed === true;
        const isPending = ttsStatus?.status === 'pending';
        
        if (isPending && !isRejected && isReviewed) {
          results.push({
            ...file,
            language: lang,
            title: langData.title,
            content: langData.content,
            ttsStatus
          });
        }
      }
    }
    
    return results;
  }

  // Update content metadata
  static async updateContent(filePath, updates) {
    const data = await FileUtils.readJSON(filePath);
    
    // Deep merge updates
    this.deepMerge(data, updates);
    data.metadata.updated_at = new Date().toISOString();
    
    await FileUtils.writeJSON(filePath, data);
    return data;
  }

  static deepMerge(target, source) {
    for (const key in source) {
      if (source[key] && typeof source[key] === 'object' && !Array.isArray(source[key])) {
        if (!target[key]) target[key] = {};
        this.deepMerge(target[key], source[key]);
      } else {
        target[key] = source[key];
      }
    }
  }

  // Check if file has missing translations
  static getMissingTranslations(fileData) {
    const status = fileData.metadata?.translation_status;
    const translatedTo = status?.translated_to || [];
    
    return LANGUAGES.SUPPORTED.filter(lang => 
      lang !== LANGUAGES.PRIMARY && !translatedTo.includes(lang)
    );
  }
}