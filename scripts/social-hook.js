#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";

// Platform-specific hook strategies
const HOOK_STRATEGIES = {
  twitter: {
    maxLength: 240, // Leave room for thread indicator
    style: "punchy",
    emoji: true,
    threadIndicator: "🧵"
  },
  linkedin: {
    maxLength: 150,
    style: "professional", 
    emoji: false,
    focus: "insight"
  },
  facebook: {
    maxLength: 200,
    style: "conversational",
    emoji: true,
    focus: "engagement"
  },
  generic: {
    maxLength: 180,
    style: "versatile",
    emoji: true,
    focus: "broad_appeal"
  }
};

async function findEnglishFile(fileId) {
  const basePath = `./content/en`;
  const categories = ['daily-news', 'ethereum', 'macro'];
  
  for (const category of categories) {
    const filePath = path.join(basePath, category, `${fileId}.json`);
    try {
      await fs.access(filePath);
      return { filePath, category };
    } catch {
      continue;
    }
  }
  
  throw new Error(`English file not found: ${fileId}`);
}

async function validateEnglishFile(filePath) {
  const content = await fs.readFile(filePath, 'utf-8');
  const data = JSON.parse(content);
  
  // Check if English content exists
  if (!data.languages?.en) {
    throw new Error('English translation not found. Run translation first.');
  }
  
  return data;
}

function extractKeyInsights(content) {
  const insights = [];
  
  // Look for compelling statements
  const sentences = content.split(/[.!?]\s+/);
  
  for (const sentence of sentences) {
    const trimmed = sentence.trim();
    if (trimmed.length > 30 && trimmed.length < 200) {
      // Look for patterns that make good hooks
      if (
        trimmed.includes('government') ||
        trimmed.includes('breakthrough') ||
        trimmed.includes('change') ||
        trimmed.includes('risk') ||
        trimmed.includes('opportunity') ||
        /\d+%/.test(trimmed) || // Contains percentage
        /\$[\d,]+/.test(trimmed) || // Contains money
        trimmed.includes('Bitcoin') ||
        trimmed.includes('crypto')
      ) {
        insights.push(trimmed);
      }
    }
  }
  
  return insights.slice(0, 5); // Top 5 insights
}

function generateHookVariations(title, content, insights) {
  const variations = [];
  
  // Question hooks
  variations.push(`Did you know: ${insights[0] || title}?`);
  variations.push(`What if I told you: ${insights[0] || 'crypto is changing finance'}?`);
  
  // Shocking fact hooks
  variations.push(`🚨 ${insights[0] || title}`);
  variations.push(`This will shock you: ${insights[0] || title}`);
  
  // Breaking news style
  variations.push(`🚀 BREAKING: ${title.replace(/^\[EN\]\s*/, '')}`);
  
  // Personal/Story hooks
  variations.push(`Here's what everyone is missing about ${extractMainTopic(title)}...`);
  variations.push(`The truth about ${extractMainTopic(title)} that nobody talks about`);
  
  // Contrarian hooks
  variations.push(`Everyone thinks ${extractMainTopic(title)} is risky, but...`);
  
  return variations.slice(0, 6); // Top 6 variations
}

function extractMainTopic(title) {
  // Extract main topic from title
  const cleanTitle = title.replace(/^\[EN\]\s*/, '');
  
  if (cleanTitle.includes('Bitcoin') || cleanTitle.includes('crypto')) {
    return 'crypto mortgages';
  }
  if (cleanTitle.includes('Fed') || cleanTitle.includes('Federal')) {
    return 'Fed policy';
  }
  if (cleanTitle.includes('Ethereum')) {
    return 'Ethereum';
  }
  
  return 'this financial trend';
}

function optimizeForPlatform(hook, platform) {
  const config = HOOK_STRATEGIES[platform] || HOOK_STRATEGIES.generic;
  
  let optimized = hook;
  
  // Add platform-specific elements
  switch (platform) {
    case 'twitter':
      if (!optimized.includes('🧵') && optimized.length > 200) {
        optimized += ' 🧵';
      }
      break;
      
    case 'linkedin':
      // Make more professional
      optimized = optimized.replace(/🚨|🚀/g, '').trim();
      if (optimized.includes('BREAKING:')) {
        optimized = optimized.replace('BREAKING:', 'Important update:');
      }
      break;
      
    case 'facebook':
      // Make more conversational
      if (!optimized.includes('Imagine') && !optimized.includes('What if')) {
        optimized = `Imagine this: ${optimized}`;
      }
      break;
  }
  
  // Truncate if needed
  if (optimized.length > config.maxLength) {
    optimized = optimized.substring(0, config.maxLength - 3) + '...';
  }
  
  return optimized;
}

function selectBestHook(variations, content) {
  // Simple scoring algorithm - in reality, this could be more sophisticated
  const scored = variations.map(hook => {
    let score = 0;
    
    // Prefer shorter hooks
    if (hook.length <= 150) score += 2;
    if (hook.length <= 100) score += 1;
    
    // Prefer hooks with engagement words
    const engagementWords = ['shocking', 'breaking', 'did you know', 'what if', 'this will'];
    for (const word of engagementWords) {
      if (hook.toLowerCase().includes(word)) score += 3;
    }
    
    // Prefer hooks with emojis (for social)
    if (/[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{1F1E0}-\u{1F1FF}]/u.test(hook)) {
      score += 1;
    }
    
    // Prefer hooks with numbers or financial terms
    if (/\d+/.test(hook) || hook.includes('Bitcoin') || hook.includes('crypto')) {
      score += 2;
    }
    
    return { hook, score };
  });
  
  scored.sort((a, b) => b.score - a.score);
  return scored[0].hook;
}

async function generateSocialHook(data, platform = 'generic') {
  const englishContent = data.languages.en;
  
  console.log(chalk.blue('🎯 Analyzing content for hook potential...'));
  
  // Extract key insights
  const insights = extractKeyInsights(englishContent.content);
  console.log(chalk.gray(`📊 Found ${insights.length} key insights`));
  
  // Generate hook variations
  const variations = generateHookVariations(
    englishContent.title,
    englishContent.content,
    insights
  );
  
  // Select best primary hook
  const primaryHook = selectBestHook(variations, englishContent.content);
  
  // Create platform-optimized versions
  const platformOptimized = {};
  for (const platform of ['twitter', 'linkedin', 'facebook']) {
    platformOptimized[platform] = optimizeForPlatform(primaryHook, platform);
  }
  
  return {
    primary: primaryHook,
    variations: variations.filter(v => v !== primaryHook),
    platform_optimized: platformOptimized,
    insights_used: insights
  };
}

async function updateFileWithHook(filePath, socialHook) {
  const content = await fs.readFile(filePath, 'utf-8');
  const data = JSON.parse(content);
  
  // Add social hook to English content
  data.languages.en.social_hook = socialHook;
  data.metadata.updated_at = new Date().toISOString();
  
  await fs.writeFile(filePath, JSON.stringify(data, null, 2));
}

function displayHookPreview(socialHook, platform) {
  console.log(chalk.green.bold(`\n🎯 Social Hook Generated`));
  console.log(chalk.gray('='.repeat(50)));
  
  console.log(chalk.yellow.bold('📱 Primary Hook:'));
  console.log(socialHook.primary);
  
  console.log(chalk.cyan.bold('\n🔄 Variations:'));
  socialHook.variations.forEach((variation, i) => {
    console.log(chalk.gray(`${i + 1}. ${variation}`));
  });
  
  console.log(chalk.blue.bold('\n📱 Platform Optimized:'));
  Object.entries(socialHook.platform_optimized).forEach(([platform, hook]) => {
    console.log(chalk.magenta(`${platform.toUpperCase()}: ${hook}`));
  });
  
  console.log(chalk.gray('='.repeat(50)));
}

async function main() {
  const args = process.argv.slice(2);
  const fileId = args.find(arg => !arg.startsWith('--'))?.replace('--file_id=', '');
  const platform = args.find(arg => arg.startsWith('--platform='))?.split('=')[1] || 'generic';
  
  if (!fileId) {
    console.error(chalk.red('❌ Error: file_id is required'));
    console.log(chalk.gray('Usage: node scripts/social-hook.js <file_id> [--platform=twitter|linkedin|facebook]'));
    process.exit(1);
  }
  
  try {
    console.log(chalk.blue.bold('🎯 Social Hook Generator'));
    console.log(chalk.gray('='.repeat(50)));
    
    // Find and validate English file
    console.log(chalk.blue('📖 Loading English content...'));
    const { filePath, category } = await findEnglishFile(fileId);
    const data = await validateEnglishFile(filePath);
    
    console.log(chalk.green(`✅ English content loaded: ${path.basename(filePath)}`));
    console.log(chalk.cyan(`📂 Category: ${category}`));
    console.log(chalk.cyan(`🎯 Platform: ${platform}`));
    
    // Generate social hook
    const socialHook = await generateSocialHook(data, platform);
    
    // Update file
    console.log(chalk.blue('💾 Saving social hook...'));
    await updateFileWithHook(filePath, socialHook);
    
    // Display preview
    displayHookPreview(socialHook, platform);
    
    console.log(chalk.green.bold('\n🎉 Social hook generated successfully!'));
    console.log(chalk.gray(`📁 Updated: ${path.basename(filePath)}`));
    console.log(chalk.gray(`📱 Ready for social media posting`));
    
  } catch (error) {
    console.error(chalk.red('❌ Hook generation failed:'), error.message);
    process.exit(1);
  }
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { findEnglishFile, generateSocialHook, extractKeyInsights };