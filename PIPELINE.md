# Content Pipeline Architecture

## New Unified Pipeline System

### Two Simple Commands

```bash
# Step 1: Review content
npm run review

# Step 2: Run full pipeline (translate → tts → social)
npm run pipeline
```

### Pipeline Features

✅ **Unified Workflow**: Single command handles translate → TTS → social  
✅ **Retry Logic**: Automatic retries with exponential backoff  
✅ **Resumable**: Interrupt with Ctrl+C, resume later with same command  
✅ **Progress Tracking**: Real-time progress bars and status  
✅ **State Management**: Tracks completed/failed files, saves progress  
✅ **Concurrent Processing**: Up to 3 files processed simultaneously  
✅ **Error Recovery**: Failed files don't stop the pipeline  

### Pipeline Commands

```bash
# Run full pipeline
npm run pipeline

# Show current status
npm run pipeline:status

# Retry only failed files
npm run pipeline:retry

# Retry specific step
npm run pipeline:retry translate
npm run pipeline:retry tts

# Reset pipeline state
npm run pipeline:reset
```

### Architecture

```
lib/
├── services/           # External service integrations
│   ├── GoogleTTS.js       # TTS API with retry logic
│   ├── GoogleDrive.js     # Drive upload with categorization
│   └── PipelineState.js   # State management & persistence
├── workflows/          # High-level orchestration
│   └── ContentPipeline.js # Main pipeline coordinator
└── utils/
    └── RetryUtils.js      # Centralized retry logic

scripts/
├── pipeline.js         # Pipeline CLI entry point
└── legacy/             # Old scripts (still available)
    ├── tts-multi.js
    ├── translate.js
    └── review.js
```

### Pipeline Flow

1. **Translation Step**
   - Finds reviewed source files needing translation
   - Translates to all target languages (en-US, ja-JP)
   - Updates translation metadata

2. **TTS Step**
   - Finds translated files needing TTS processing
   - Generates speech with Google TTS API
   - Uploads to category-specific Google Drive folders
   - Updates TTS metadata with Drive URLs

3. **Social Step** (placeholder)
   - Future: Generate social media content
   - Currently: No-op completion

### State Management

Pipeline state is saved in `pipeline-state.json`:
- Current step (translate/tts/social)
- Completed files per step
- Failed files with error details
- Progress tracking

### Error Handling

- **Automatic Retries**: TTS API and Drive upload failures
- **Graceful Interruption**: Ctrl+C saves state and allows resume
- **Failed File Tracking**: Failed files don't block other files
- **Step-by-Step Recovery**: Can retry specific pipeline steps

### Category-Aware Upload

TTS files are uploaded to category-specific folders:
- `daily-news` → Voice config folders[daily-news]
- `ethereum` → Voice config folders[ethereum]  
- `macro` → Voice config folders[macro]

### Migration from Legacy

Legacy scripts still available as:
- `npm run legacy-review`
- `npm run legacy-translate`
- `npm run legacy-tts`

New pipeline provides same functionality with better reliability and user experience.

### Development

For debugging or extending the pipeline:

```bash
# Show detailed pipeline status
npm run pipeline:status

# Reset state for clean run
npm run pipeline:reset

# Test individual services
node -e "import('./lib/services/GoogleTTS.js').then(m => console.log('TTS service OK'))"
```