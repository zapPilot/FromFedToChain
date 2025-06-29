import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert';
import fs from 'fs/promises';
import path from 'path';
import { FileUtils } from '../lib/utils/FileUtils.js';
import { TestUtils } from './setup.js';

describe('FileUtils', () => {
  let tempDir;

  beforeEach(async () => {
    tempDir = await TestUtils.createTempDir();
  });

  afterEach(async () => {
    await TestUtils.cleanupTempDir(tempDir);
  });

  it('should read and write JSON files correctly', async () => {
    const testData = TestUtils.createMockContent();
    const filePath = path.join(tempDir, 'test.json');

    await FileUtils.writeJSON(filePath, testData);
    const readData = await FileUtils.readJSON(filePath);

    assert.deepEqual(readData, testData);
  });

  it('should validate content schema', async () => {
    const validContent = TestUtils.createMockContent();
    const invalidContent = { invalid: 'data' };

    assert.doesNotThrow(() => FileUtils.validateContentSchema(validContent));
    assert.throws(() => FileUtils.validateContentSchema(invalidContent));
  });

  it('should generate correct content paths', () => {
    const path1 = FileUtils.getContentPath('en-US', 'daily-news', 'test-file');
    const path2 = FileUtils.getContentPath('ja-JP', 'ethereum', 'another-file');

    assert.equal(path1, './content/en-US/daily-news/test-file.json');
    assert.equal(path2, './content/ja-JP/ethereum/another-file.json');
  });

  it('should handle file scanning with filters', async () => {
    // Create test files
    const content1 = TestUtils.createMockContent({ 
      id: 'file1', 
      metadata: { translation_status: { source_reviewed: true } }
    });
    const content2 = TestUtils.createMockContent({ 
      id: 'file2', 
      metadata: { translation_status: { source_reviewed: false } }
    });

    const contentDir = path.join(tempDir, 'content', 'zh-TW', 'daily-news');
    await fs.mkdir(contentDir, { recursive: true });
    
    await FileUtils.writeJSON(path.join(contentDir, 'file1.json'), content1);
    await FileUtils.writeJSON(path.join(contentDir, 'file2.json'), content2);

    // Mock the content root for testing
    const originalContentRoot = process.env.CONTENT_ROOT;
    process.env.CONTENT_ROOT = path.join(tempDir, 'content');

    const reviewedFiles = await FileUtils.scanContentFiles((file) => 
      file.data.metadata?.translation_status?.source_reviewed === true
    );

    assert.equal(reviewedFiles.length, 1);
    assert.equal(reviewedFiles[0].id, 'file1');

    process.env.CONTENT_ROOT = originalContentRoot;
  });
});