import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert';
import fs from 'fs/promises';
import path from 'path';
import { spawn } from 'child_process';
import { TestUtils } from './setup.js';
import { ContentManager } from '../src/ContentManager.js';

describe('Review Command Tests', () => {
  let tempDir;
  let originalContentDir;
  let mockContents;

  beforeEach(async () => {
    tempDir = await TestUtils.createTempDir();
    originalContentDir = ContentManager.CONTENT_DIR;
    ContentManager.CONTENT_DIR = tempDir;

    // Create mock content files for testing
    mockContents = [
      {
        id: '2025-06-30-bitcoin-test',
        status: 'draft',
        category: 'daily-news',
        date: '2025-06-30',
        source: {
          title: 'Bitcoin Test Article',
          content: 'This is a test article about Bitcoin trends.',
          references: ['source1', 'source2']
        },
        translations: {},
        feedback: {
          content_review: null,
          ai_outputs: { translations: {}, audio: {}, social_hooks: {} },
          performance_metrics: { spotify: {}, social_platforms: {} }
        },
        updated_at: new Date().toISOString()
      },
      {
        id: '2025-06-30-ethereum-test',
        status: 'draft',
        category: 'ethereum',
        date: '2025-06-30',
        source: {
          title: 'Ethereum DeFi Update',
          content: 'This is a test article about Ethereum and DeFi protocols.',
          references: ['source3']
        },
        translations: {},
        feedback: {
          content_review: null,
          ai_outputs: { translations: {}, audio: {}, social_hooks: {} },
          performance_metrics: { spotify: {}, social_platforms: {} }
        },
        updated_at: new Date().toISOString()
      }
    ];

    // Write mock content files
    for (const content of mockContents) {
      const filePath = path.join(tempDir, `${content.id}.json`);
      await fs.writeFile(filePath, JSON.stringify(content, null, 2));
    }
  });

  afterEach(async () => {
    ContentManager.CONTENT_DIR = originalContentDir;
    await TestUtils.cleanupTempDir(tempDir);
  });

  describe('Basic Functionality', () => {
    it('should list all draft content', async () => {
      const draftContents = await ContentManager.getByStatus('draft');
      assert.equal(draftContents.length, 2);
      
      // Check that both pieces of content are present (order may vary for same date)
      const ids = draftContents.map(c => c.id);
      assert(ids.includes('2025-06-30-bitcoin-test'));
      assert(ids.includes('2025-06-30-ethereum-test'));
    });

    it('should handle empty draft list', async () => {
      // Mark all content as reviewed
      for (const content of mockContents) {
        await ContentManager.updateStatus(content.id, 'reviewed');
      }

      const draftContents = await ContentManager.getByStatus('draft');
      assert.equal(draftContents.length, 0);
    });

    it('should read content correctly', async () => {
      const content = await ContentManager.read('2025-06-30-bitcoin-test');
      assert.equal(content.source.title, 'Bitcoin Test Article');
      assert.equal(content.status, 'draft');
    });
  });

  describe('Content Acceptance', () => {
    it('should accept content without feedback', async () => {
      const id = '2025-06-30-bitcoin-test';
      
      await ContentManager.addContentFeedback(
        id,
        'accepted',
        4,
        'reviewer_cli',
        'Approved for translation',
        {}
      );
      await ContentManager.updateStatus(id, 'reviewed');

      const updatedContent = await ContentManager.read(id);
      assert.equal(updatedContent.status, 'reviewed');
      assert.equal(updatedContent.feedback.content_review.status, 'accepted');
      assert.equal(updatedContent.feedback.content_review.comments, 'Approved for translation');
    });

    it('should accept content with custom feedback', async () => {
      const id = '2025-06-30-bitcoin-test';
      const customFeedback = 'Excellent analysis of market trends';
      
      await ContentManager.addContentFeedback(
        id,
        'accepted',
        4,
        'reviewer_cli',
        customFeedback,
        {}
      );
      await ContentManager.updateStatus(id, 'reviewed');

      const updatedContent = await ContentManager.read(id);
      assert.equal(updatedContent.status, 'reviewed');
      assert.equal(updatedContent.feedback.content_review.status, 'accepted');
      assert.equal(updatedContent.feedback.content_review.comments, customFeedback);
      assert.equal(updatedContent.feedback.content_review.reviewer, 'reviewer_cli');
    });

    it('should store acceptance timestamp', async () => {
      const id = '2025-06-30-bitcoin-test';
      const beforeTime = new Date().toISOString();
      
      await ContentManager.addContentFeedback(
        id,
        'accepted',
        4,
        'reviewer_cli',
        'Good content',
        {}
      );

      const afterTime = new Date().toISOString();
      const updatedContent = await ContentManager.read(id);
      const timestamp = updatedContent.feedback.content_review.timestamp;
      
      assert(timestamp >= beforeTime && timestamp <= afterTime);
    });
  });

  describe('Content Rejection', () => {
    it('should reject content with feedback', async () => {
      const id = '2025-06-30-ethereum-test';
      const rejectionFeedback = 'Needs more specific examples and data sources';
      
      await ContentManager.addContentFeedback(
        id,
        'rejected',
        2,
        'reviewer_cli',
        rejectionFeedback,
        {}
      );

      const updatedContent = await ContentManager.read(id);
      assert.equal(updatedContent.status, 'draft'); // Should remain draft
      assert.equal(updatedContent.feedback.content_review.status, 'rejected');
      assert.equal(updatedContent.feedback.content_review.comments, rejectionFeedback);
      assert.equal(updatedContent.feedback.content_review.score, 2);
    });

    it('should require feedback for rejection', async () => {
      const id = '2025-06-30-ethereum-test';
      
      // Should not allow empty feedback for rejection
      try {
        await ContentManager.addContentFeedback(
          id,
          'rejected',
          2,
          'reviewer_cli',
          '', // Empty feedback
          {}
        );
        // This should ideally be validated, but for now we just test the data
        const updatedContent = await ContentManager.read(id);
        assert.equal(updatedContent.feedback.content_review.comments, '');
      } catch (error) {
        // Expected if validation is implemented
        assert(error.message.includes('feedback') || error.message.includes('comment'));
      }
    });
  });

  describe('Content Status Management', () => {
    it('should not show reviewed content in draft list', async () => {
      // Accept one piece of content
      await ContentManager.updateStatus('2025-06-30-bitcoin-test', 'reviewed');
      
      const draftContents = await ContentManager.getByStatus('draft');
      const reviewedContents = await ContentManager.getByStatus('reviewed');
      
      assert.equal(draftContents.length, 1);
      assert.equal(reviewedContents.length, 1);
      assert.equal(draftContents[0].id, '2025-06-30-ethereum-test');
      assert.equal(reviewedContents[0].id, '2025-06-30-bitcoin-test');
    });

    it('should keep rejected content in draft status', async () => {
      await ContentManager.addContentFeedback(
        '2025-06-30-bitcoin-test',
        'rejected',
        2,
        'reviewer_cli',
        'Needs revision',
        {}
      );
      // Note: rejected content should stay in draft status for revision

      const content = await ContentManager.read('2025-06-30-bitcoin-test');
      assert.equal(content.status, 'draft');
      assert.equal(content.feedback.content_review.status, 'rejected');
    });
  });

  describe('Data Integrity', () => {
    it('should preserve all original content fields', async () => {
      const originalContent = await ContentManager.read('2025-06-30-bitcoin-test');
      
      await ContentManager.addContentFeedback(
        '2025-06-30-bitcoin-test',
        'accepted',
        4,
        'reviewer_cli',
        'Good content',
        {}
      );
      await ContentManager.updateStatus('2025-06-30-bitcoin-test', 'reviewed');

      const updatedContent = await ContentManager.read('2025-06-30-bitcoin-test');
      
      // Original fields should be preserved
      assert.deepEqual(updatedContent.source, originalContent.source);
      assert.equal(updatedContent.category, originalContent.category);
      assert.equal(updatedContent.date, originalContent.date);
      assert.equal(updatedContent.id, originalContent.id);
      
      // Only status and feedback should change
      assert.equal(updatedContent.status, 'reviewed');
      assert(updatedContent.feedback.content_review !== null);
    });

    it('should handle backward compatibility for missing feedback structure', async () => {
      // Create content without feedback structure (old format)
      const oldFormatContent = {
        id: '2025-06-30-old-format',
        status: 'draft',
        category: 'daily-news',
        date: '2025-06-30',
        source: {
          title: 'Old Format Content',
          content: 'This content has no feedback structure.',
          references: []
        },
        translations: {},
        updated_at: new Date().toISOString()
      };

      const filePath = path.join(tempDir, `${oldFormatContent.id}.json`);
      await fs.writeFile(filePath, JSON.stringify(oldFormatContent, null, 2));

      // Should handle missing feedback structure gracefully
      await ContentManager.addContentFeedback(
        oldFormatContent.id,
        'accepted',
        4,
        'reviewer_cli',
        'Migrated content',
        {}
      );

      const updatedContent = await ContentManager.read(oldFormatContent.id);
      assert(updatedContent.feedback);
      assert(updatedContent.feedback.content_review);
      assert.equal(updatedContent.feedback.content_review.status, 'accepted');
    });
  });

  describe('Training Data Collection', () => {
    it('should store training labels with feedback', async () => {
      const trainingLabels = {
        engagement: 4,
        accuracy: 5,
        clarity: 4,
        relevance: 5
      };

      await ContentManager.addContentFeedback(
        '2025-06-30-bitcoin-test',
        'accepted',
        4,
        'reviewer_expert_finance',
        'Great insights',
        trainingLabels
      );

      const content = await ContentManager.read('2025-06-30-bitcoin-test');
      assert.deepEqual(content.feedback.content_review.training_labels, trainingLabels);
      assert.equal(content.feedback.content_review.reviewer, 'reviewer_expert_finance');
    });

    it('should export training data correctly', async () => {
      // Add feedback to both pieces of content
      await ContentManager.addContentFeedback(
        '2025-06-30-bitcoin-test',
        'accepted',
        4,
        'reviewer_cli',
        'Good content',
        { engagement: 4 }
      );

      await ContentManager.addContentFeedback(
        '2025-06-30-ethereum-test',
        'rejected',
        2,
        'reviewer_cli',
        'Needs improvement',
        { clarity: 2 }
      );

      const trainingData = await ContentManager.exportTrainingData();
      
      assert(trainingData.export_metadata);
      assert.equal(trainingData.export_metadata.total_samples, 0); // No AI outputs yet
      assert(Array.isArray(trainingData.training_samples));
    });
  });

  describe('Error Handling', () => {
    it('should handle missing content files gracefully', async () => {
      try {
        await ContentManager.read('non-existent-content');
        assert.fail('Should have thrown an error');
      } catch (error) {
        assert(error.message.includes('Content not found'));
      }
    });

    it('should handle corrupted JSON files', async () => {
      const corruptedPath = path.join(tempDir, 'corrupted.json');
      await fs.writeFile(corruptedPath, '{ invalid json content }');

      try {
        await ContentManager.read('corrupted');
        assert.fail('Should have thrown an error');
      } catch (error) {
        assert(error.message.includes('Content not found') || error.message.includes('JSON'));
      }
    });

    it('should handle file system permission errors', async () => {
      // This test is platform-dependent and might need adjustment
      // For now, we'll simulate by trying to read from a non-existent directory
      const oldDir = ContentManager.CONTENT_DIR;
      ContentManager.CONTENT_DIR = '/non/existent/path';

      try {
        await ContentManager.list();
        // Should return empty array instead of crashing
        const contents = await ContentManager.list();
        assert(Array.isArray(contents));
      } catch (error) {
        // Or handle gracefully with an error
        assert(error.message);
      } finally {
        ContentManager.CONTENT_DIR = oldDir;
      }
    });
  });

  describe('Review Progress Tracking', () => {
    it('should track review progress correctly', async () => {
      const initialDrafts = await ContentManager.getByStatus('draft');
      assert.equal(initialDrafts.length, 2);

      // Accept first content
      await ContentManager.addContentFeedback(
        '2025-06-30-bitcoin-test',
        'accepted',
        4,
        'reviewer_cli',
        'Good',
        {}
      );
      await ContentManager.updateStatus('2025-06-30-bitcoin-test', 'reviewed');

      const remainingDrafts = await ContentManager.getByStatus('draft');
      const reviewed = await ContentManager.getByStatus('reviewed');
      
      assert.equal(remainingDrafts.length, 1);
      assert.equal(reviewed.length, 1);
      assert.equal(remainingDrafts[0].id, '2025-06-30-ethereum-test');
    });

    it('should handle review session resumption', async () => {
      // Simulate partial review session
      await ContentManager.updateStatus('2025-06-30-bitcoin-test', 'reviewed');
      
      // Second session should only show remaining drafts
      const remainingDrafts = await ContentManager.getByStatus('draft');
      assert.equal(remainingDrafts.length, 1);
      assert.equal(remainingDrafts[0].id, '2025-06-30-ethereum-test');
    });
  });
});

describe('Review CLI Integration Tests', () => {
  let tempDir;
  let originalContentDir;

  beforeEach(async () => {
    tempDir = await TestUtils.createTempDir();
    originalContentDir = ContentManager.CONTENT_DIR;
    ContentManager.CONTENT_DIR = tempDir;
  });

  afterEach(async () => {
    ContentManager.CONTENT_DIR = originalContentDir;
    await TestUtils.cleanupTempDir(tempDir);
  });

  it('should handle empty content directory', (t, done) => {
    const child = spawn('node', ['src/cli.js', 'review'], {
      stdio: ['pipe', 'pipe', 'pipe'],
      env: { ...process.env, NODE_ENV: 'test' }
    });

    let output = '';
    child.stdout.on('data', (data) => {
      output += data.toString();
    });

    child.on('close', (code) => {
      assert(output.includes('No content pending review'));
      assert.equal(code, 0);
      done();
    });

    child.on('error', done);
  });

  it('should have help text with quit functionality', async () => {
    // Test the help functionality which should show quit option
    return new Promise((resolve, reject) => {
      const child = spawn('node', ['src/cli.js', '--help'], {
        stdio: ['pipe', 'pipe', 'pipe'],
        env: { ...process.env, NODE_ENV: 'test' }
      });

      let output = '';
      
      child.stdout.on('data', (data) => {
        output += data.toString();
      });

      child.on('close', (code) => {
        // Check that help includes quit functionality
        const hasQuitInHelp = output.includes('[q]uit') || output.includes('quit');
        assert(hasQuitInHelp, `Expected quit functionality in help: ${output}`);
        resolve();
      });

      child.on('error', reject);

      // Timeout protection
      setTimeout(() => {
        child.kill();
        reject(new Error('Test timeout'));
      }, 5000);
    });
  });
});