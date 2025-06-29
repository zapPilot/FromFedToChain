#!/usr/bin/env node

import { CLI } from './lib/ui/CLI.js';

// Run CLI with command line arguments
CLI.run(process.argv.slice(2));