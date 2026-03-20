#!/usr/bin/env node
/**
 * validate-compose.js
 * Validates compose.yaml has the expected services and port mappings.
 */

import { readFileSync, existsSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';

const __dirname = dirname(fileURLToPath(import.meta.url));

const COMPOSE_FILE = join(__dirname, 'compose.yaml');

const REQUIRED_SERVICES = ['daemon', 'backend', 'marketfeed', 'nginx'];
const REQUIRED_PORTS = ['5000:5000', '8080:80', '443:443'];

function main() {
  if (!existsSync(COMPOSE_FILE)) {
    console.error('ERROR: compose.yaml not found');
    process.exit(1);
  }

  const content = readFileSync(COMPOSE_FILE, 'utf8');
  let errors = 0;

  for (const svc of REQUIRED_SERVICES) {
    const pattern = new RegExp(`^  ${svc}:`, 'm');
    if (!pattern.test(content)) {
      console.error(`MISSING SERVICE: ${svc}`);
      errors++;
    } else {
      console.log(`OK service: ${svc}`);
    }
  }

  for (const port of REQUIRED_PORTS) {
    if (!content.includes(`"${port}"`)) {
      console.error(`MISSING PORT MAPPING: ${port}`);
      errors++;
    } else {
      console.log(`OK port: ${port}`);
    }
  }

  if (errors > 0) {
    console.error(`\nValidation failed with ${errors} error(s).`);
    process.exit(1);
  }

  console.log('\ncompose.yaml validation passed.');
}

main();
