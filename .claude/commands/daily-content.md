# Daily Content Pipeline

**Name:** `daily-content`  
**Description:** Complete "From Fed to Chain" content pipeline - generate content, review, convert to speech, and upload
**Parameters:**
- `category` (optional): Content focus area - `daily-news`, `ethereum`, or `macro`

## What this command does:

1. **🔍 Search & Research:** Find relevant news following category guidelines in `/guidelines/categories/`
2. **📝 Generate Content:** Write conversational Traditional Chinese explainer in 得到/樊登讀書會 style  
3. **💾 Save:** Create structured JSON content in `/content/zh-TW/{category}/`
4. **👀 Review Prompt:** Present content for your review and approval before translation

## Category Guidelines:

Each category has specific topic selection criteria and style guidelines:
- **`daily-news`**: Current crypto/macro news affecting daily financial decisions
- **`ethereum`**: Ethereum ecosystem developments and deep analysis  
- **`macro`**: Macroeconomic trends intersecting with cryptocurrency

See `/guidelines/categories/{category}.md` for detailed guidelines before content generation.

## Multi-Language Pipeline:

### Step 1: Generate Traditional Chinese Content
```bash
claude daily-content [--category daily-news|ethereum|macro]
```
- Searches current crypto/macro news with daily-life relevance
- Creates conversational Traditional Chinese script
- Saves to `/content/zh-TW/{category}/YYYY-MM-DD-topic-name.json`
- Sets `source_reviewed: false` for human review

## File Structure Created:
```
/content/zh-TW/daily-news/YYYY-MM-DD-topic-name.json  # Original Chinese
/content/en/daily-news/YYYY-MM-DD-topic-name.json     # Translated + social hook
```

## Content Format:

Content follows the structured JSON schema defined in `schema.json`. See the schema file for complete format specification and validation rules.

---

*This command starts the multi-language content pipeline. Use subsequent commands for translation, social hooks, and TTS processing.*