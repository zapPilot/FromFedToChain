import chalk from "chalk";

export class Logger {
  static title(text) {
    console.log(chalk.blue.bold(text));
    console.log(chalk.gray("=".repeat(50)));
  }

  static info(text) {
    console.log(chalk.blue(text));
  }

  static success(text) {
    console.log(chalk.green(text));
  }

  static warning(text) {
    console.log(chalk.yellow(text));
  }

  static error(text) {
    console.log(chalk.red(text));
  }

  static gray(text) {
    console.log(chalk.gray(text));
  }

  static step(current, total, text) {
    console.log(chalk.blue(`[${current}/${total}] ${text}`));
  }
}
