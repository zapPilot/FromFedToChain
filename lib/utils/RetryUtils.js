import chalk from "chalk";

/**
 * Centralized retry logic with exponential backoff
 */
export class RetryUtils {
  static async retryOperation(operation, options = {}) {
    const {
      maxRetries = 3,
      initialDelay = 1000,
      maxDelay = 10000,
      backoffFactor = 2,
      onRetry = null,
      retryCondition = () => true,
    } = options;

    let lastError;
    let delay = initialDelay;

    for (let attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;

        if (attempt === maxRetries || !retryCondition(error)) {
          throw error;
        }

        if (onRetry) {
          onRetry(error, attempt, maxRetries);
        } else {
          console.log(
            chalk.yellow(`  ⚠️  Attempt ${attempt} failed: ${error.message}`),
          );
          console.log(
            chalk.gray(
              `  ⏳ Retrying in ${delay}ms... (${attempt}/${maxRetries})`,
            ),
          );
        }

        await new Promise((resolve) => setTimeout(resolve, delay));
        delay = Math.min(delay * backoffFactor, maxDelay);
      }
    }

    throw lastError;
  }

  static isRetryableError(error) {
    // Common retryable error patterns
    const retryablePatterns = [
      /timeout/i,
      /network/i,
      /connection/i,
      /rate limit/i,
      /quota/i,
      /503/,
      /502/,
      /500/,
    ];

    return retryablePatterns.some(
      (pattern) => pattern.test(error.message) || pattern.test(error.code),
    );
  }
}
