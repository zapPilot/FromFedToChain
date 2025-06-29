import chalk from "chalk";
import cliProgress from "cli-progress";

export class ProgressBar {
  constructor(total, format = null) {
    this.bar = new cliProgress.SingleBar(
      {
        format:
          format ||
          chalk.cyan("{bar}") + " {percentage}% | {value}/{total} | {status}",
        barCompleteChar: "\u2588",
        barIncompleteChar: "\u2591",
        hideCursor: true,
      },
      cliProgress.Presets.rect,
    );

    this.total = total;
  }

  start(status = "Starting...") {
    this.bar.start(this.total, 0, { status });
  }

  update(value, status = "") {
    this.bar.update(value, { status });
  }

  stop() {
    this.bar.stop();
  }

  increment(status = "") {
    this.bar.increment({ status });
  }
}
