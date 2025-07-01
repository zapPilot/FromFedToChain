import { describe, it, beforeEach, afterEach, mock } from 'node:test';
import assert from 'node:assert';
import { GoogleTTSService } from '../src/services/GoogleTTSService.js';

describe('GoogleTTSService Batching Tests', () => {
  let mockClient;
  let ttsService;
  let originalClient;

  beforeEach(() => {
    // Mock the TextToSpeechClient
    mockClient = {
      synthesizeSpeech: mock.fn()
    };

    ttsService = new GoogleTTSService();
    originalClient = ttsService.client;
    ttsService.client = mockClient;
  });

  afterEach(() => {
    if (originalClient) {
      ttsService.client = originalClient;
    }
    mock.restoreAll();
  });

  // Helper function to create mock audio content (WAV format)
  function createMockAudioContent(size = 1000) {
    // Create a simple mock WAV file with header
    const buffer = Buffer.alloc(size);
    
    // Write WAV header (simplified)
    buffer.write('RIFF', 0);
    buffer.writeUInt32LE(size - 8, 4);
    buffer.write('WAVE', 8);
    buffer.write('fmt ', 12);
    buffer.writeUInt32LE(16, 16); // format chunk size
    buffer.writeUInt16LE(1, 20);  // audio format (PCM)
    buffer.writeUInt16LE(1, 22);  // number of channels
    buffer.writeUInt32LE(16000, 24); // sample rate
    buffer.writeUInt32LE(32000, 28); // byte rate
    buffer.writeUInt16LE(2, 32);  // block align
    buffer.writeUInt16LE(16, 34); // bits per sample
    buffer.write('data', 36);
    buffer.writeUInt32LE(size - 44, 40); // data chunk size
    
    // Fill rest with dummy audio data
    for (let i = 44; i < size; i++) {
      buffer[i] = Math.floor(Math.random() * 256);
    }
    
    return buffer;
  }

  describe('Content Chunking', () => {
    it('should not split content under byte limit', () => {
      const shortContent = 'This is a short content that should not be split.';
      const chunks = ttsService.splitContentIntoChunks(shortContent);
      
      assert.strictEqual(chunks.length, 1);
      assert.strictEqual(chunks[0], shortContent);
    });

    it('should split large content into multiple chunks', () => {
      // Create content that exceeds 4800 bytes
      const largeContent = 'This is a very long paragraph. '.repeat(200); // ~6200 bytes
      const chunks = ttsService.splitContentIntoChunks(largeContent);
      
      assert(chunks.length > 1, 'Should split large content into multiple chunks');
      
      // Verify each chunk is under the limit
      chunks.forEach((chunk, index) => {
        const chunkBytes = Buffer.byteLength(chunk, 'utf8');
        assert(chunkBytes <= 4800, `Chunk ${index} should be under 4800 bytes, got ${chunkBytes}`);
      });
    });

    it('should preserve paragraph boundaries when splitting', () => {
      const content = [
        'First paragraph with enough content to make it substantial. ' +
        'This paragraph continues with more text to ensure it has enough content. ' +
        'Adding even more text to make this paragraph longer.',
        
        'Second paragraph that also has significant content. ' +
        'This paragraph also continues with additional text. ' +
        'More text to make this paragraph substantial as well.',
        
        'Third paragraph with its own content. ' +
        'This paragraph has even more text to make it longer. ' +
        'Final sentences to complete this paragraph.'
      ].join('\n\n');

      const chunks = ttsService.splitContentIntoChunks(content);
      
      // Should have multiple chunks
      assert(chunks.length >= 1);
      
      // Each chunk should contain complete paragraphs when possible
      chunks.forEach(chunk => {
        assert(chunk.trim().length > 0, 'Chunk should not be empty');
      });
    });

    it('should split very long paragraphs by sentences', () => {
      // Create a single very long paragraph
      const longParagraph = Array(50).fill(
        'This is a sentence that forms part of a very long paragraph. '
      ).join('');
      
      const chunks = ttsService.splitContentIntoChunks(longParagraph);
      
      assert(chunks.length > 1, 'Should split long paragraph into multiple chunks');
      
      // Verify chunks end with punctuation when possible
      chunks.forEach((chunk, index) => {
        if (index < chunks.length - 1) { // Not the last chunk
          assert(chunk.match(/[.!?]$/) || chunk.endsWith('...'), 
                 `Chunk ${index} should end with punctuation`);
        }
      });
    });

    it('should handle content with mixed paragraph sizes', () => {
      const content = [
        'Short paragraph.',
        
        'Medium length paragraph with several sentences. ' +
        'This paragraph has multiple sentences to test splitting. ' +
        'The final sentence completes this paragraph.',
        
        Array(100).fill('Very long paragraph sentence. ').join(''), // Very long paragraph
        
        'Another short paragraph.',
        
        Array(80).fill('Another long paragraph sentence. ').join('') // Another long paragraph
      ].join('\n\n');

      const chunks = ttsService.splitContentIntoChunks(content);
      
      assert(chunks.length > 1, 'Should split mixed content appropriately');
      
      // Verify all chunks are under limit
      chunks.forEach((chunk, index) => {
        const chunkBytes = Buffer.byteLength(chunk, 'utf8');
        assert(chunkBytes <= 4800, `Chunk ${index} exceeds byte limit: ${chunkBytes}`);
      });
    });

    it('should handle edge case of extremely long single sentence', () => {
      // Create a single sentence that exceeds the limit
      const extremelyLongSentence = 'This is an extremely long sentence that just keeps going and going without any periods or breaks ' +
        'and continues for a very long time '.repeat(100) + 'and finally ends.';
      
      const chunks = ttsService.splitContentIntoChunks(extremelyLongSentence);
      
      assert(chunks.length > 1, 'Should force split extremely long sentence');
      
      // Verify last chunk indicates truncation
      const lastChunk = chunks[chunks.length - 1];
      assert(lastChunk.endsWith('...'), 'Last chunk should indicate truncation');
    });

    it('should handle empty content gracefully', () => {
      const chunks = ttsService.splitContentIntoChunks('');
      assert.strictEqual(chunks.length, 0, 'Empty content should return no chunks');
    });

    it('should handle content with only whitespace', () => {
      const chunks = ttsService.splitContentIntoChunks('   \n\n  \t  \n   ');
      assert.strictEqual(chunks.length, 0, 'Whitespace-only content should return no chunks');
    });
  });

  describe('Single Chunk TTS', () => {
    it('should process single chunk normally', async () => {
      const mockAudioContent = createMockAudioContent(1000);
      mockClient.synthesizeSpeech.mock.mockImplementation(() => 
        Promise.resolve([{ audioContent: mockAudioContent }])
      );

      const shortContent = 'This is short content.';
      const voiceConfig = { languageCode: 'en-US', name: 'en-US-Wavenet-D' };
      
      const result = await ttsService.synthesizeSpeech(shortContent, voiceConfig);
      
      assert.strictEqual(mockClient.synthesizeSpeech.mock.callCount(), 1);
      assert(result.audioContent);
      assert.strictEqual(result.audioContent.length, mockAudioContent.length);
    });

    it('should pass correct parameters to TTS client', async () => {
      const mockAudioContent = createMockAudioContent(500);
      mockClient.synthesizeSpeech.mock.mockImplementation(() => 
        Promise.resolve([{ audioContent: mockAudioContent }])
      );

      const content = 'Test content for TTS.';
      const voiceConfig = { languageCode: 'ja-JP', name: 'ja-JP-Wavenet-A' };
      
      await ttsService.synthesizeSpeech(content, voiceConfig);
      
      const callArgs = mockClient.synthesizeSpeech.mock.calls[0].arguments[0];
      assert.strictEqual(callArgs.input.text, content);
      assert.strictEqual(callArgs.voice.languageCode, 'ja-JP');
      assert.strictEqual(callArgs.voice.name, 'ja-JP-Wavenet-A');
      assert.strictEqual(callArgs.audioConfig.audioEncoding, 'LINEAR16');
      assert.strictEqual(callArgs.audioConfig.sampleRateHertz, 16000);
    });
  });

  describe('Batched TTS Processing', () => {
    it('should process multiple chunks and combine audio', async () => {
      // Create mock audio for each chunk
      const audioChunk1 = createMockAudioContent(800);
      const audioChunk2 = createMockAudioContent(600);
      const audioChunk3 = createMockAudioContent(700);

      let callCount = 0;
      mockClient.synthesizeSpeech.mock.mockImplementation(() => {
        callCount++;
        switch (callCount) {
          case 1: return Promise.resolve([{ audioContent: audioChunk1 }]);
          case 2: return Promise.resolve([{ audioContent: audioChunk2 }]);
          case 3: return Promise.resolve([{ audioContent: audioChunk3 }]);
          default: throw new Error('Unexpected call count');
        }
      });

      // Create content that will be split into 3 chunks
      const largeContent = Array(60).fill('This is a paragraph that will be split. ').join('');
      const voiceConfig = { languageCode: 'en-US', name: 'en-US-Wavenet-D' };
      
      const result = await ttsService.synthesizeSpeech(largeContent, voiceConfig);
      
      // Should have called TTS service 3 times
      assert.strictEqual(mockClient.synthesizeSpeech.mock.callCount(), 3);
      
      // Result should have combined audio
      assert(result.audioContent);
      
      // Combined audio should be larger than any individual chunk
      assert(result.audioContent.length > audioChunk1.length);
      assert(result.audioContent.length > audioChunk2.length);
      assert(result.audioContent.length > audioChunk3.length);
    });

    it('should add delays between chunk requests', async () => {
      const mockAudioContent = createMockAudioContent(500);
      const timestamps = [];
      
      mockClient.synthesizeSpeech.mock.mockImplementation(() => {
        timestamps.push(Date.now());
        return Promise.resolve([{ audioContent: mockAudioContent }]);
      });

      // Create content requiring multiple chunks
      const largeContent = Array(40).fill('This is content that needs batching. ').join('');
      const voiceConfig = { languageCode: 'en-US', name: 'en-US-Wavenet-D' };
      
      await ttsService.synthesizeSpeech(largeContent, voiceConfig);
      
      // Should have multiple calls with delays
      if (timestamps.length > 1) {
        for (let i = 1; i < timestamps.length; i++) {
          const delay = timestamps[i] - timestamps[i - 1];
          assert(delay >= 450, `Delay between calls should be at least 450ms, got ${delay}ms`);
        }
      }
    });

    it('should handle batching errors gracefully', async () => {
      let callCount = 0;
      mockClient.synthesizeSpeech.mock.mockImplementation(() => {
        callCount++;
        if (callCount === 2) {
          throw new Error('TTS service temporarily unavailable');
        }
        return Promise.resolve([{ audioContent: createMockAudioContent(500) }]);
      });

      const largeContent = Array(40).fill('Content that will cause an error. ').join('');
      const voiceConfig = { languageCode: 'en-US', name: 'en-US-Wavenet-D' };
      
      await assert.rejects(
        async () => {
          await ttsService.synthesizeSpeech(largeContent, voiceConfig);
        },
        {
          name: 'Error',
          message: 'TTS service temporarily unavailable'
        }
      );
    });
  });

  describe('Audio Combination', () => {
    it('should correctly combine WAV audio chunks', () => {
      const chunk1 = createMockAudioContent(1000);
      const chunk2 = createMockAudioContent(800);
      const chunk3 = createMockAudioContent(600);
      
      const combined = ttsService.combineAudioChunks([chunk1, chunk2, chunk3]);
      
      // Combined length should be: first chunk + (second chunk - header) + (third chunk - header)
      const expectedLength = chunk1.length + (chunk2.length - 44) + (chunk3.length - 44);
      assert.strictEqual(combined.length, expectedLength);
      
      // Should start with WAV header from first chunk
      assert.strictEqual(combined.toString('ascii', 0, 4), 'RIFF');
      assert.strictEqual(combined.toString('ascii', 8, 12), 'WAVE');
    });

    it('should update WAV header with correct file size', () => {
      const chunk1 = createMockAudioContent(1000);
      const chunk2 = createMockAudioContent(800);
      
      const combined = ttsService.combineAudioChunks([chunk1, chunk2]);
      
      // Read file size from WAV header (bytes 4-7)
      const fileSizeFromHeader = combined.readUInt32LE(4);
      const expectedFileSize = combined.length - 8;
      assert.strictEqual(fileSizeFromHeader, expectedFileSize);
      
      // Read data chunk size from WAV header (bytes 40-43)
      const dataSizeFromHeader = combined.readUInt32LE(40);
      const expectedDataSize = combined.length - 44;
      assert.strictEqual(dataSizeFromHeader, expectedDataSize);
    });

    it('should handle single chunk combination', () => {
      const singleChunk = createMockAudioContent(1000);
      const combined = ttsService.combineAudioChunks([singleChunk]);
      
      // Combined should be identical to original
      assert.strictEqual(combined.length, singleChunk.length);
      assert(combined.equals(singleChunk));
    });

    it('should handle empty chunks array', () => {
      assert.throws(() => {
        ttsService.combineAudioChunks([]);
      }, /Cannot read properties/);
    });
  });

  describe('Content Preparation Integration', () => {
    it('should work with prepareContentForTTS output', async () => {
      const mockAudioContent = createMockAudioContent(1000);
      mockClient.synthesizeSpeech.mock.mockImplementation(() => 
        Promise.resolve([{ audioContent: mockAudioContent }])
      );

      const rawContent = `
# Bitcoin News

**Bitcoin** has reached a new *all-time high* today!

This is [very exciting](https://example.com) news for the crypto community.

## Market Analysis

The price surge can be attributed to several factors:

1. Institutional adoption
2. Regulatory clarity
3. Technical improvements

\`\`\`
Price: $65,000
Volume: $2B
\`\`\`

Visit our [website](https://crypto.com) for more details.
      `.trim();

      const preparedContent = GoogleTTSService.prepareContentForTTS(rawContent, 'en-US');
      const voiceConfig = { languageCode: 'en-US', name: 'en-US-Wavenet-D' };
      
      const result = await ttsService.synthesizeSpeech(preparedContent, voiceConfig);
      
      assert(result.audioContent);
      assert(result.audioContent.length > 0);
      
      // Verify prepared content doesn't have markdown
      assert(!preparedContent.includes('**'));
      assert(!preparedContent.includes('*'));
      assert(!preparedContent.includes('['));
      assert(!preparedContent.includes('#'));
      assert(!preparedContent.includes('```'));
    });
  });

  describe('Error Handling and Edge Cases', () => {
    it('should handle TTS service errors during batching', async () => {
      mockClient.synthesizeSpeech.mock.mockImplementation(() => 
        Promise.reject(new Error('API quota exceeded'))
      );

      const largeContent = Array(50).fill('Content that will cause API error. ').join('');
      const voiceConfig = { languageCode: 'en-US', name: 'en-US-Wavenet-D' };
      
      await assert.rejects(
        async () => {
          await ttsService.synthesizeSpeech(largeContent, voiceConfig);
        },
        {
          name: 'Error',
          message: 'API quota exceeded'
        }
      );
    });

    it('should handle malformed audio chunks', () => {
      const validChunk = createMockAudioContent(1000);
      const invalidChunk = Buffer.alloc(10); // Too small to be valid WAV
      
      assert.throws(() => {
        ttsService.combineAudioChunks([validChunk, invalidChunk]);
      }, /Cannot read properties/);
    });

    it('should handle extremely large content', () => {
      // Create content that would require many chunks
      const extremeContent = Array(1000).fill('This is repeated content. ').join('');
      const chunks = ttsService.splitContentIntoChunks(extremeContent);
      
      assert(chunks.length > 10, 'Should create many chunks for extreme content');
      
      // Verify all chunks are under limit
      chunks.forEach((chunk, index) => {
        const chunkBytes = Buffer.byteLength(chunk, 'utf8');
        assert(chunkBytes <= 4800, `Chunk ${index} exceeds limit`);
      });
    });

    it('should preserve content semantics across chunks', () => {
      const content = [
        'Introduction paragraph explaining the topic.',
        'First main point with detailed explanation and examples.',
        'Second main point with supporting evidence and analysis.',
        'Third main point with comprehensive coverage.',
        'Conclusion summarizing all the key points discussed.'
      ].join('\n\n');

      const chunks = ttsService.splitContentIntoChunks(content);
      
      // Rejoin chunks to verify no content loss
      const rejoined = chunks.join(' ');
      
      // Should contain all major keywords
      assert(rejoined.includes('Introduction'));
      assert(rejoined.includes('First main point'));
      assert(rejoined.includes('Second main point'));
      assert(rejoined.includes('Third main point'));
      assert(rejoined.includes('Conclusion'));
    });
  });
});