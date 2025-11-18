#!/usr/bin/env node

/**
 * Schema Synchronization Validation Script
 *
 * Validates that schema constants (languages, categories, statuses) are synchronized
 * between TypeScript (Node.js CLI) and Dart (Flutter app) codebases.
 *
 * Exit codes:
 * - 0: All schemas are synchronized
 * - 1: One or more schemas are out of sync
 */

import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import { ContentSchema } from "../src/ContentSchema.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PROJECT_ROOT = path.resolve(__dirname, "..");

// ANSI color codes
const colors = {
  reset: "\x1b[0m",
  green: "\x1b[32m",
  red: "\x1b[31m",
  yellow: "\x1b[33m",
  blue: "\x1b[34m",
  cyan: "\x1b[36m",
};

/**
 * Extract array constants from Dart code using regex
 */
function extractDartArrayConstant(content, pattern) {
  const match = content.match(pattern);
  if (!match) return null;

  // Extract array content between [ and ]
  const arrayMatch = match[0].match(/\[(.*?)\]/s);
  if (!arrayMatch) return null;

  // Parse array elements (strings in quotes)
  const elements = arrayMatch[1]
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0)
    .map((s) => s.replace(/['"]/g, "")); // Remove quotes

  return elements;
}

/**
 * Extract switch case values from Dart code
 */
function extractDartSwitchCases(content, pattern) {
  const match = content.match(pattern);
  if (!match) return null;

  // Extract all case statements
  const casePattern = /case\s+['"]([^'"]+)['"]\s*:/g;
  const cases = [];
  let caseMatch;

  while ((caseMatch = casePattern.exec(match[0])) !== null) {
    cases.push(caseMatch[1]);
  }

  return cases.length > 0 ? cases : null;
}

/**
 * Compare two arrays (order-agnostic)
 */
function compareArrays(arr1, arr2, label) {
  const set1 = new Set(arr1);
  const set2 = new Set(arr2);

  const missing = arr1.filter((x) => !set2.has(x));
  const extra = arr2.filter((x) => !set1.has(x));

  const isSync = missing.length === 0 && extra.length === 0;

  return {
    isSync,
    missing,
    extra,
    label,
    typescript: arr1,
    dart: arr2,
  };
}

/**
 * Print comparison result
 */
function printResult(result) {
  const icon = result.isSync
    ? `${colors.green}✅${colors.reset}`
    : `${colors.red}❌${colors.reset}`;
  const status = result.isSync
    ? `${colors.green}PASS${colors.reset}`
    : `${colors.red}FAIL${colors.reset}`;

  console.log(`${icon} ${result.label}: ${status}`);

  if (result.isSync) {
    console.log(
      `   ${colors.cyan}TypeScript:${colors.reset} [${result.typescript.join(", ")}]`,
    );
    console.log(
      `   ${colors.cyan}Dart:      ${colors.reset} [${result.dart.join(", ")}]`,
    );
  } else {
    console.log(
      `   ${colors.cyan}TypeScript:${colors.reset} [${result.typescript.join(", ")}]`,
    );
    console.log(
      `   ${colors.cyan}Dart:      ${colors.reset} [${result.dart.join(", ")}]`,
    );

    if (result.missing.length > 0) {
      console.log(
        `   ${colors.yellow}Missing in Dart:${colors.reset} [${result.missing.join(", ")}]`,
      );
    }

    if (result.extra.length > 0) {
      console.log(
        `   ${colors.yellow}Extra in Dart:  ${colors.reset} [${result.extra.join(", ")}]`,
      );
    }
  }

  console.log();
}

/**
 * Main validation function
 */
async function validateSchemaSync() {
  console.log(
    `\n${colors.blue}🔍 Schema Synchronization Validation${colors.reset}`,
  );
  console.log("=====================================\n");

  const results = [];

  try {
    // 1. Validate Languages
    // TypeScript: Use getAllLanguages() to include zh-TW
    const tsLanguages = ContentSchema.getAllLanguages();

    // Dart: Read from api_config.dart
    const apiConfigPath = path.join(
      PROJECT_ROOT,
      "app",
      "lib",
      "config",
      "api_config.dart",
    );
    const apiConfigContent = await fs.readFile(apiConfigPath, "utf-8");

    const dartLanguages = extractDartArrayConstant(
      apiConfigContent,
      /static\s+const\s+List<String>\s+supportedLanguages\s*=\s*\[[\s\S]*?\];/,
    );

    if (!dartLanguages) {
      throw new Error(
        "Could not extract supportedLanguages from api_config.dart",
      );
    }

    results.push(
      compareArrays(tsLanguages, dartLanguages, "Languages synchronization"),
    );

    // 2. Validate Categories
    const tsCategories = ContentSchema.getCategories();

    const dartCategories = extractDartArrayConstant(
      apiConfigContent,
      /static\s+const\s+List<String>\s+supportedCategories\s*=\s*\[[\s\S]*?\];/,
    );

    if (!dartCategories) {
      throw new Error(
        "Could not extract supportedCategories from api_config.dart",
      );
    }

    results.push(
      compareArrays(tsCategories, dartCategories, "Categories synchronization"),
    );

    // 3. Validate Audio Statuses
    // TypeScript: Get statuses from 'wav' onwards (where audio is available)
    const allStatuses = ContentSchema.getStatuses();
    const wavIndex = allStatuses.indexOf("wav");
    const tsAudioStatuses = allStatuses.slice(wavIndex);

    // Dart: Read from audio_content.dart hasAudio getter
    const audioContentPath = path.join(
      PROJECT_ROOT,
      "app",
      "lib",
      "models",
      "audio_content.dart",
    );
    const audioContentContent = await fs.readFile(audioContentPath, "utf-8");

    const dartAudioStatuses = extractDartSwitchCases(
      audioContentContent,
      /bool\s+get\s+hasAudio\s*\{[\s\S]*?switch\s*\(status\)\s*\{[\s\S]*?return\s+true;[\s\S]*?\}/,
    );

    if (!dartAudioStatuses) {
      throw new Error(
        "Could not extract audio statuses from audio_content.dart hasAudio getter",
      );
    }

    results.push(
      compareArrays(
        tsAudioStatuses,
        dartAudioStatuses,
        "Audio statuses synchronization",
      ),
    );

    // Print results
    results.forEach(printResult);

    // Summary
    console.log("=====================================");

    const failedCount = results.filter((r) => !r.isSync).length;

    if (failedCount === 0) {
      console.log(
        `${colors.green}✅ Validation PASSED: All schemas are synchronized${colors.reset}\n`,
      );
      return 0;
    } else {
      console.log(
        `${colors.red}❌ Validation FAILED: ${failedCount} check(s) failed${colors.reset}\n`,
      );

      // Print fix instructions
      console.log(`${colors.yellow}Fix Instructions:${colors.reset}`);
      console.log("1. Update constants in the files showing mismatches above");
      console.log(
        "2. Refer to CLAUDE.md 'Schema Synchronization Requirements' section",
      );
      console.log("3. Run 'npm test' and 'flutter test' to verify changes\n");

      return 1;
    }
  } catch (error) {
    console.error(
      `${colors.red}❌ Validation Error:${colors.reset}`,
      error.message,
    );
    console.error("\nStack trace:", error.stack);
    return 1;
  }
}

// Run validation
validateSchemaSync()
  .then((exitCode) => {
    process.exit(exitCode);
  })
  .catch((error) => {
    console.error(`${colors.red}Fatal error:${colors.reset}`, error);
    process.exit(1);
  });
