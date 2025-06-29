# Google Cloud Platform Setup

## Enable Translation API

To use real Google Cloud Translation instead of mock translation, you need to enable the Translation API:

### Steps:

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Select your project** (the same one used for TTS)
3. **Enable Translation API**:
   - Go to: https://console.developers.google.com/apis/api/translate.googleapis.com/overview
   - Click "Enable API"
   - Wait a few minutes for the API to activate

### Verify Setup:

```bash
# Test GCP Translation API
node scripts/test-gcp-translation.js
```

If successful, you should see translated text output.

### Usage:

```bash
# Use mock translation (default, no API required)
npm run pipeline
npm run pipeline:mock

# Use real Google Cloud Translation API
npm run pipeline:gcp
```

### Language Support:

Currently configured languages:

- **Source**: Traditional Chinese (`zh-TW`)
- **Targets**: English (`en`), Japanese (`ja`)

### API Costs:

Google Cloud Translation pricing (as of 2024):

- **First 500,000 characters/month**: Free
- **Additional characters**: $20 per 1M characters

For typical crypto content (~5000 characters per article):

- **Free tier**: ~100 articles/month
- **Paid usage**: ~$0.10 per article

### Troubleshooting:

1. **"API not enabled" error**: Enable Translation API in Cloud Console
2. **Authentication errors**: Verify `service-account.json` is correct
3. **Quota exceeded**: Check Cloud Console > APIs & Services > Quotas
4. **Project mismatch**: Ensure service account belongs to correct project

### Benefits of GCP Translation vs Mock:

✅ **Real Translation**: Actual language translation (not just prefixed text)
✅ **Professional Quality**: Google's neural machine translation
✅ **Consistent**: Same translation for same input
✅ **Fast**: Direct API calls, no CLI overhead
✅ **Reliable**: Built-in retry logic and error handling

Mock translation is useful for:

- Testing pipeline functionality
- Development without API costs
- When translation quality is not important
