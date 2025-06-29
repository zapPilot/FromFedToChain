# Content Translation Pipeline

**Name:** `translate`  
**Description:** Translate reviewed Traditional Chinese content to English with social media formatting
**Parameters:**

- `file_id` (required): Content ID to translate (e.g., "2025-06-28-crypto-mortgage-breakthrough")
- `target_lang` (optional): Target language (default: "en")

## What this command does:

1. **📖 Read Source:** Load reviewed Traditional Chinese content
2. **🔄 Translate:** Convert to natural English maintaining conversational style
3. **📱 Social Format:** Create hook + full script for social media
4. **💾 Save:** Create English version following schema
5. **🔗 Link:** Update metadata with translation status

## Usage:

```bash
claude translate --file_id 2025-06-28-crypto-mortgage-breakthrough
claude translate --file_id 2025-06-28-fed-policy --target_lang en
```

## Translation Guidelines:

### Style Requirements:

- **Conversational**: Maintain friendly, accessible tone
- **Natural**: Sound like native English speaker
- **Engaging**: Keep the storytelling approach
- **Educational**: Preserve explanatory structure

### Social Media Format:

- **Hook**: 1-2 sentences to grab attention
- **Full Script**: Complete translated content for posting

### Content Structure:

```
🚀 [HOOK]
Compelling opening that makes people want to read more...

[FULL CONTENT]
Complete translated explanation maintaining the original structure and insights...
```

## File Processing:

### Input Requirements:

- Source file must exist in `content/zh-TW/{category}/`
- `source_reviewed: true` in metadata
- Valid JSON schema format

### Output:

- Creates `content/en/{category}/{file_id}.json`
- Updates source file metadata with translation status
- Includes social media formatting

## Translation Process:

1. **Validation**: Check source file exists and is reviewed
2. **Content Analysis**: Understand context and key points
3. **Translation**: Convert while preserving style and meaning
4. **Social Formatting**: Create engaging hook and format full script
5. **Save**: Write English version with complete metadata

## Quality Checks:

- Maintains conversational tone
- Preserves key insights and examples
- Creates compelling social media hook
- Follows proper JSON schema
- Links translation metadata correctly

---

_This command handles the complete zh-TW → en translation workflow with social media optimization._
