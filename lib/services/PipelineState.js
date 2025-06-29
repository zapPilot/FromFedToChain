import fs from "fs/promises";
import path from "path";
import chalk from "chalk";

export class PipelineStateManager {
  constructor(stateFile = "./pipeline-state.json") {
    this.stateFile = stateFile;
    this.state = {
      currentStep: "translate",
      completedFiles: {},
      failedFiles: {},
      lastRun: null,
      totalFiles: 0,
      processedFiles: 0,
    };
  }

  async loadState() {
    try {
      const content = await fs.readFile(this.stateFile, "utf-8");
      this.state = { ...this.state, ...JSON.parse(content) };
      return this.state;
    } catch (error) {
      // File doesn't exist, use default state
      return this.state;
    }
  }

  async saveState() {
    this.state.lastRun = new Date().toISOString();
    await fs.writeFile(this.stateFile, JSON.stringify(this.state, null, 2));
  }

  setCurrentStep(step) {
    this.state.currentStep = step;
  }

  setTotalFiles(count) {
    this.state.totalFiles = count;
  }

  markFileCompleted(fileId, step, result = {}) {
    if (!this.state.completedFiles[step]) {
      this.state.completedFiles[step] = {};
    }
    this.state.completedFiles[step][fileId] = {
      completedAt: new Date().toISOString(),
      ...result,
    };
    this.state.processedFiles++;
  }

  markFileFailed(fileId, step, error) {
    if (!this.state.failedFiles[step]) {
      this.state.failedFiles[step] = {};
    }
    this.state.failedFiles[step][fileId] = {
      failedAt: new Date().toISOString(),
      error: error.message || error,
    };
  }

  isFileCompleted(fileId, step) {
    return this.state.completedFiles[step]?.hasOwnProperty(fileId) || false;
  }

  isFileFailed(fileId, step) {
    return this.state.failedFiles[step]?.hasOwnProperty(fileId) || false;
  }

  getFailedFiles(step = null) {
    if (step) {
      return this.state.failedFiles[step] || {};
    }
    return this.state.failedFiles;
  }

  clearFailedFiles(step = null) {
    if (step) {
      this.state.failedFiles[step] = {};
    } else {
      this.state.failedFiles = {};
    }
  }

  getProgressSummary() {
    const steps = ["translate", "tts", "social"];
    const summary = {
      currentStep: this.state.currentStep,
      totalFiles: this.state.totalFiles,
      processedFiles: this.state.processedFiles,
      steps: {},
    };

    steps.forEach((step) => {
      const completed = Object.keys(
        this.state.completedFiles[step] || {},
      ).length;
      const failed = Object.keys(this.state.failedFiles[step] || {}).length;
      summary.steps[step] = { completed, failed };
    });

    return summary;
  }

  printStatus() {
    const summary = this.getProgressSummary();

    console.log(chalk.blue.bold("\n📊 Pipeline Status"));
    console.log(chalk.gray("=".repeat(30)));
    console.log(chalk.cyan(`Current Step: ${summary.currentStep}`));
    console.log(chalk.gray(`Last Run: ${this.state.lastRun || "Never"}`));

    Object.entries(summary.steps).forEach(([step, stats]) => {
      const total = stats.completed + stats.failed;
      if (total > 0) {
        console.log(
          chalk.blue(`${step}:`),
          chalk.green(`✓${stats.completed}`),
          chalk.red(`✗${stats.failed}`),
        );
      }
    });

    if (summary.totalFiles > 0) {
      const progress = Math.round(
        (summary.processedFiles / summary.totalFiles) * 100,
      );
      console.log(
        chalk.yellow(
          `Progress: ${summary.processedFiles}/${summary.totalFiles} (${progress}%)`,
        ),
      );
    }
  }

  async reset() {
    this.state = {
      currentStep: "translate",
      completedFiles: {},
      failedFiles: {},
      lastRun: null,
      totalFiles: 0,
      processedFiles: 0,
    };
    await this.saveState();
    console.log(chalk.green("✅ Pipeline state reset"));
  }
}
