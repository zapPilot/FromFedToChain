# Social Hook Generator

**Name:** `social-hook`  
**Description:** Generate compelling social media hooks for English content
**Parameters:**
- `file_id` (required): Content ID to generate hook for (e.g., "2025-06-28-crypto-mortgage-breakthrough")
- `platform` (optional): Platform optimization (default: "generic")

## What this command does:

1. **📖 Read English Content:** Load translated English content
2. **🎯 Analyze Hook Potential:** Identify compelling angles and hooks  
3. **📱 Generate Hooks:** Create platform-optimized social media hooks
4. **💾 Save:** Add social hook to English content metadata
5. **📋 Preview:** Show formatted social media posts

## Usage:

```bash
claude social-hook --file_id 2025-06-28-crypto-mortgage-breakthrough
claude social-hook --file_id 2025-06-28-fed-policy --platform twitter
```

## Hook Generation Strategy:

### Hook Types:
- **Question Hook**: "Did you know that..."
- **Shocking Fact**: "🚨 This will change everything..."  
- **Personal Story**: "Here's what happened when..."
- **Contrarian Take**: "Everyone thinks X, but actually..."
- **Urgent News**: "🚀 BREAKING: Government just announced..."

### Platform Optimization:
- **Twitter**: Short, punchy, thread-ready
- **LinkedIn**: Professional, insightful
- **Facebook**: Engaging, discussion-starter
- **Generic**: Versatile for multiple platforms

## Content Requirements:

### Input Requirements:
- English content must exist in `content/en/{category}/`
- Translation must be completed
- Valid JSON schema format

### Output:
- Updates English file with `social_hook` field
- Generates multiple hook variations
- Creates platform-specific formatting

## Hook Quality Criteria:

- **Compelling**: Makes people want to read more
- **Clear**: Easy to understand at a glance
- **Relevant**: Matches the content's key insight
- **Actionable**: Encourages engagement
- **Platform-Appropriate**: Fits platform culture

## Generated Format:
```json
{
  "languages": {
    "en": {
      "title": "...",
      "content": "...",
      "social_hook": {
        "primary": "🚨 The US government just approved Bitcoin mortgages. Here's why this changes everything for crypto holders...",
        "variations": [
          "Question: Would you use your Bitcoin as collateral for a house?",
          "🏠 Your Bitcoin could soon buy you a house (without selling it)",
          "Breaking: Traditional banks vs crypto lenders - the race is on"
        ],
        "platform_optimized": {
          "twitter": "🚨 US gov approves Bitcoin mortgages. This changes everything for crypto holders... 🧵",
          "linkedin": "The intersection of traditional finance and cryptocurrency just reached a major milestone.",
          "facebook": "Imagine using your Bitcoin to buy a house without selling it. It's now possible."
        }
      }
    }
  }
}
```

---

*This command handles social media hook generation and optimization for English content.*