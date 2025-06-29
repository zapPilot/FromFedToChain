#!/usr/bin/env node

import fs from "fs/promises";
import path from "path";
import chalk from "chalk";
import readline from "readline";

// --- Constants ---
const LANG = 'zh-TW';
const CATEGORIES = ['daily-news', 'ethereum', 'macro'];
const CONTENT_ROOT = './content/zh-TW';

// --- Utility Functions ---
/**
 * Prompt the user for input in the terminal.
 * @param {string} query
 * @returns {Promise<string>}
 */
function askQuestion(query) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) =>
    rl.question(query, (ans) => {
      rl.close();
      resolve(ans);
    })
  );
}

/**
 * Safely get a nested property from an object.
 * @param {object} obj
 * @param {string} path
 * @param {*} fallback
 * @returns {*}
 */
function getNested(obj, path, fallback = undefined) {
  return path.split('.').reduce((o, k) => (o || {})[k], obj) ?? fallback;
}

/**
 * Set a nested property on an object, creating intermediate objects as needed.
 * @param {object} obj
 * @param {string} path
 * @param {*} value
 */
function setNested(obj, path, value) {
  const keys = path.split('.');
  let o = obj;
  for (let i = 0; i < keys.length - 1; i++) {
    if (!o[keys[i]]) o[keys[i]] = {};
    o = o[keys[i]];
  }
  o[keys[keys.length - 1]] = value;
}

// --- File Scanning ---
/**
 * Recursively scan a directory for unreviewed JSON content files.
 * @param {string} dir
 * @param {Array} pendingFiles
 */
async function scanDirectoryForUnreviewed(dir, pendingFiles) {
  const items = await fs.readdir(dir, { withFileTypes: true });
  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      await scanDirectoryForUnreviewed(fullPath, pendingFiles);
    } else if (item.name.endsWith('.json')) {
      try {
        const content = await fs.readFile(fullPath, 'utf-8');
        const data = JSON.parse(content);
        if (
          data.metadata &&
          data.metadata.translation_status &&
          data.metadata.translation_status.source_reviewed === false
        ) {
          pendingFiles.push({ path: fullPath, data });
        }
      } catch (error) {
        console.log(chalk.yellow(`⚠️  Warning: Could not parse JSON file ${fullPath}`));
      }
    }
  }
}

/**
 * Find all unreviewed JSON content files in all category subfolders.
 * @returns {Promise<Array<{path: string, data: object}>>}
 */
async function findPendingJSONContent() {
  const pendingFiles = [];
  for (const category of CATEGORIES) {
    const categoryDir = path.join(CONTENT_ROOT, category);
    try {
      await scanDirectoryForUnreviewed(categoryDir, pendingFiles);
    } catch (e) {
      // Ignore missing category folders
    }
  }
  return pendingFiles;
}

// --- Content Display ---
/**
 * Display a content file for review in the terminal.
 * @param {object} data
 */
function displayContentForReview(data) {
  const langData = data.languages && data.languages[LANG] ? data.languages[LANG] : {};
  console.log(chalk.blue.bold('\n📄 Content Preview'));
  console.log(chalk.gray('='.repeat(50)));
  console.log(chalk.green.bold(`Title: ${langData.title || '[No title]'}`));
  console.log(chalk.cyan(`Date: ${data.date}`));
  console.log(chalk.magenta(`Category: ${data.category}`));
  if (data.references && data.references.length > 0) {
    console.log(chalk.yellow(`References: ${data.references.join(', ')}`));
  }
  console.log(chalk.gray('\n--- Content (to be processed by TTS) ---'));
  console.log(langData.content || '[No content]');
  const ttsStatus = data.metadata && data.metadata.tts && data.metadata.tts[LANG] ? data.metadata.tts[LANG].status : '[Unknown]';
  const audioUrl = data.metadata && data.metadata.tts && data.metadata.tts[LANG] ? data.metadata.tts[LANG].audio_url : '[Not generated]';
  console.log(chalk.gray('\n--- TTS Status ---'));
  console.log(`Status: ${ttsStatus}`);
  console.log(`Audio URL: ${audioUrl}`);
  console.log(chalk.gray('='.repeat(50)));
}

// --- Review Logic ---
/**
 * Interactively review a content file, updating its review status.
 * @param {{path: string, data: object}} file
 * @returns {Promise<boolean>} true if approved, false if rejected
 */
async function reviewFile(file) {
  displayContentForReview(file.data);
  let answer = await askQuestion(chalk.yellow('Approve this content? (y/n): '));
  answer = answer.trim().toLowerCase();
  if (answer === 'n' || answer === 'no') {
    const reason = await askQuestion(chalk.red('Enter rejection reason: '));
    const timestamp = new Date().toISOString();
    if (!getNested(file.data, 'metadata.translation_status.rejection')) {
      setNested(file.data, 'metadata.translation_status.rejection', {});
    }
    setNested(file.data, 'metadata.translation_status.rejection.rejected', true);
    setNested(file.data, 'metadata.translation_status.rejection.reason', reason);
    setNested(file.data, 'metadata.translation_status.rejection.timestamp', timestamp);
    setNested(file.data, 'metadata.translation_status.source_reviewed', true);
    await fs.writeFile(file.path, JSON.stringify(file.data, null, 2), 'utf-8');
    console.log(chalk.red(`Marked as rejected. Reason: ${reason}`));
    return false;
  } else if (answer === 'y' || answer === 'yes') {
    setNested(file.data, 'metadata.translation_status.source_reviewed', true);
    setNested(file.data, 'metadata.translation_status.rejection', {
      rejected: false,
      reason: '',
      timestamp: ''
    });
    await fs.writeFile(file.path, JSON.stringify(file.data, null, 2), 'utf-8');
    console.log(chalk.green('Approved.'));
    return true;
  } else {
    console.log(chalk.yellow('Please enter y (approve) or n (reject).'));
    return await reviewFile(file);
  }
}

// --- Main Entry Point ---
async function main() {
  try {
    console.log(chalk.blue.bold('🔍 Scanning for JSON content pending review...'));
    const pendingFiles = await findPendingJSONContent();
    if (pendingFiles.length === 0) {
      console.log(chalk.green('✅ No content found for review.'));
      return;
    }
    console.log(chalk.yellow(`📝 Found ${pendingFiles.length} file(s) pending review:`));
    for (let i = 0; i < pendingFiles.length; i++) {
      const file = pendingFiles[i];
      console.log(chalk.blue.bold(`\n[${i + 1}/${pendingFiles.length}] Reviewing file: ${path.basename(file.path)}`));
      await reviewFile(file);
      if (i < pendingFiles.length - 1) {
        await askQuestion(chalk.gray('\nPress Enter to continue to the next file...'));
      }
    }
    console.log(chalk.green.bold('\n🎉 All content reviewed!'));
    console.log(chalk.gray('To edit content, modify the corresponding JSON file directly.'));
    console.log(chalk.gray('Once confirmed, you can run the TTS script for audio conversion.'));
  } catch (error) {
    console.error(chalk.red('❌ Error:'), error);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { findPendingJSONContent, displayContentForReview };