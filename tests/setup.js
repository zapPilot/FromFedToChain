// Test setup and utilities
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export class TestUtils {
  static async createTempDir() {
    const tempDir = path.join(__dirname, 'temp', `${Date.now()}-${Math.random().toString(36).substring(7)}`);
    await fs.mkdir(tempDir, { recursive: true });
    return tempDir;
  }

  static async cleanupTempDir(tempDir) {
    try {
      await fs.rm(tempDir, { recursive: true, force: true });
    } catch (error) {
      // Ignore cleanup errors
    }
  }

  static createMockContent(overrides = {}) {
    return {
      id: '2025-06-29-test-content',
      category: 'daily-news',
      language: {
        'zh-TW': {
          title: '測試標題',
          content: '測試內容文字'
        },
        'en-US': {
          title: 'Test Title',
          content: 'Test content text'
        }
      },
      metadata: {
        translation_status: { source_reviewed: true },
        tts: {
          'zh-TW': { status: 'pending' },
          'en-US': { status: 'pending' }
        }
      },
      ...overrides
    };
  }

  static mockClaudeCommand() {
    // Mock claude -p command for testing
    return {
      stdout: '🚨 Breaking: This is a test social hook for crypto news!',
      stderr: '',
      exitCode: 0
    };
  }
}