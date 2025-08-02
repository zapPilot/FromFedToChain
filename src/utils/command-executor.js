import { execSync } from "child_process";

/**
 * Executes a shell command synchronously.
 * @param {string} command The command to execute.
 * @param {object} options Options for child_process.execSync.
 * @returns {Buffer|string} The stdout from the command.
 */
export function executeCommandSync(command, options) {
  return execSync(command, options);
}
