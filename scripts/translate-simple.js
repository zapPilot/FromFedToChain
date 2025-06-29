#!/usr/bin/env node

import { CLI } from "../lib/ui/CLI.js";

// Simple wrapper for translation functionality
CLI.run(["translate", ...process.argv.slice(2)]);
