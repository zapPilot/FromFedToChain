# Content Guidelines

This directory contains category-specific guidelines for the "From Fed to Chain" content pipeline.

## 📁 Structure

```
guidelines/
├── README.md              # This file
└── categories/
    ├── daily-news.md       # Daily crypto/macro news guidelines
    ├── ethereum.md         # Ethereum ecosystem deep-dives
    └── macro.md           # Macroeconomic analysis guidelines
```

## 🎯 Purpose

These guidelines help content creators understand:

- **What topics fit each category**
- **Target audience for each category**
- **Content style and tone expectations**
- **Research sources and quality standards**
- **Content structure recommendations**

## 📋 Category Overview

### Daily News (`daily-news`)

- **Focus**: Current crypto/macro news affecting daily financial decisions
- **Style**: Accessible, conversational (得到/樊登讀書會 style)
- **Length**: 2000-3000 characters
- **Update Frequency**: Daily/regular

### Ethereum (`ethereum`)

- **Focus**: Ethereum ecosystem developments and deep analysis
- **Style**: Educational but accessible, more technical than daily-news
- **Length**: 3000-4000 characters
- **Update Frequency**: Weekly/as major developments occur

### Macro (`macro`)

- **Focus**: Macroeconomic trends intersecting with cryptocurrency
- **Style**: Sophisticated economic analysis, policy-focused
- **Length**: 3500-4500 characters
- **Update Frequency**: Bi-weekly/following major economic events

## 🔄 Usage in Pipeline

These guidelines are referenced during:

1. **Content Generation** (`claude daily-content --category {category}`)
   - Informs topic selection and research direction
   - Guides content style and structure
   - Ensures audience-appropriate tone

2. **Content Review** (`npm run review`)
   - Quality checklist for human reviewers
   - Verification against category criteria
   - Style and tone consistency check

3. **Translation** (`claude translate`)
   - Maintains category-appropriate style in English
   - Preserves intended audience and tone

## 📝 How to Use

### For Content Creators:

1. **Read the relevant category guideline** before starting research
2. **Use the topic selection criteria** to evaluate potential stories
3. **Follow the content structure guidelines** for consistent format
4. **Reference the quality checklist** before finalizing content

### For Reviewers:

1. **Check against category guidelines** during review process
2. **Verify topic relevance** using the criteria
3. **Ensure style consistency** with category expectations
4. **Use quality checklist** for comprehensive review

### For Translators:

1. **Understand the category context** to maintain appropriate tone
2. **Preserve the target audience focus** in translation
3. **Adapt examples** while maintaining educational value

## 🔄 Guideline Updates

Guidelines should be updated when:

- **Audience feedback** suggests refinement needed
- **Content performance** indicates category drift
- **Market evolution** requires topic scope adjustment
- **Style consistency** issues are identified

---

_These guidelines ensure consistent, high-quality content that serves each category's specific audience and purpose._
