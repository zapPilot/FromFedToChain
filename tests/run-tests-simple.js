#!/usr/bin/env node

// Simple test runner that avoids built-in test runner serialization issues
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
  console.log(chalk.blue.bold("🧪 Running Tests (Simple Runner)"));
  console.log(chalk.gray("=".repeat(50)));

  try {
    // Find all test files
    const testFiles = await findTestFiles("./tests");

    if (testFiles.length === 0) {
      console.log(chalk.yellow("⚠️  No test files found"));
      return;
    }

    console.log(chalk.cyan(`📁 Found ${testFiles.length} test files`));

    // Run tests one by one to avoid serialization issues
    let failedTests = 0;
    let totalTests = 0;

    for (const testFile of testFiles) {
      console.log(chalk.cyan(`\n📄 Running: ${path.basename(testFile)}`));

      try {
        const testProcess = spawn("node", ["--test", testFile], {
          stdio: "inherit",
          env: {
            ...process.env,
            NODE_ENV: "test",
            NODE_OPTIONS: "--max-old-space-size=4096",
          },
        });

        await new Promise((resolve, reject) => {
          testProcess.on("close", (code) => {
            if (code === 0) {
              console.log(chalk.green(`✅ ${path.basename(testFile)} passed`));
              totalTests++;
              resolve();
            } else {
              console.log(chalk.red(`❌ ${path.basename(testFile)} failed`));
              failedTests++;
              totalTests++;
              resolve(); // Don't reject, continue with other tests
            }
          });

          testProcess.on("error", (error) => {
            console.error(
              chalk.red(`❌ Failed to run ${path.basename(testFile)}:`),
              error.message,
            );
            failedTests++;
            totalTests++;
            resolve(); // Don't reject, continue with other tests
          });
        });
      } catch (error) {
        console.error(
          chalk.red(`❌ Error running ${path.basename(testFile)}:`),
          error.message,
        );
        failedTests++;
        totalTests++;
      }
    }

    console.log(chalk.gray("\n" + "=".repeat(50)));
    if (failedTests === 0) {
      console.log(
        chalk.green.bold(`\n✅ All ${totalTests} test files passed!`),
      );
      process.exit(0);
    } else {
      console.log(
        chalk.red.bold(`\n❌ ${failedTests}/${totalTests} test files failed`),
      );
      process.exit(1);
    }
  } catch (error) {
    console.error(chalk.red("❌ Test runner error:"), error.message);
    process.exit(1);
  }
}

runTests();
