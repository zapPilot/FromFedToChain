#!/usr/bin/env node

// Simple test runner using Node.js built-in test runner
import { spawn } from "child_process";
import fs from "fs/promises";
import path from "path";
import chalk from "chalk";

async function findTestFiles(dir) {
  const files = [];
  const items = await fs.readdir(dir, { withFileTypes: true });

  for (const item of items) {
    const fullPath = path.join(dir, item.name);
    if (item.isDirectory()) {
      files.push(...(await findTestFiles(fullPath)));
    } else if (item.name.endsWith(".test.js")) {
      files.push(fullPath);
    }
  }

  return files;
}

async function runTests() {
  console.log(chalk.blue.bold("🧪 Running Tests"));
  console.log(chalk.gray("=".repeat(50)));

  try {
    // Find all test files
    const testFiles = await findTestFiles("./tests");

    if (testFiles.length === 0) {
      console.log(chalk.yellow("⚠️  No test files found"));
      return;
    }

    console.log(chalk.cyan(`📁 Found ${testFiles.length} test files`));

    // Run tests using Node.js built-in test runner with disabled isolation to prevent mock serialization issues
    const testProcess = spawn(
      "node",
      ["--test", "--test-isolation=none", ...testFiles],
      {
        stdio: "inherit",
        env: { ...process.env, NODE_ENV: "test" },
      },
    );

    testProcess.on("close", (code) => {
      if (code === 0) {
        console.log(chalk.green.bold("\n✅ All tests passed!"));
        process.exit(0);
      } else {
        console.log(chalk.red.bold("\n❌ Some tests failed"));
        process.exit(code);
      }
    });

    testProcess.on("error", (error) => {
      console.error(chalk.red("❌ Failed to run tests:"), error.message);
      process.exit(1);
    });
  } catch (error) {
    console.error(chalk.red("❌ Test runner error:"), error.message);
    process.exit(1);
  }
}

runTests();
