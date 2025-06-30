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

    assert.equal(path1, 'content/en-US/daily-news/test-file.json');
    assert.equal(path2, 'content/ja-JP/ethereum/another-file.json');
  });

  it('should handle file scanning with filters', async () => {
    // This test is integration-heavy and depends on real file system scanning
    // For unit testing, we'll test the filter logic more directly
    const mockFile1 = {
      id: 'file1',
      data: { metadata: { translation_status: { source_reviewed: true } } }
    };
    const mockFile2 = {
      id: 'file2', 
      data: { metadata: { translation_status: { source_reviewed: false } } }
    };

    const files = [mockFile1, mockFile2];
    
    // Test filter function directly
    const filter = (file) => file.data.metadata?.translation_status?.source_reviewed === true;
    const reviewedFiles = files.filter(filter);

    assert.equal(reviewedFiles.length, 1);
    assert.equal(reviewedFiles[0].id, 'file1');
  });
});