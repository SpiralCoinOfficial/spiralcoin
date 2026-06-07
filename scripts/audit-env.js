#!/usr/bin/env node
import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const root = path.resolve(__dirname, '..');

const rootEnvPath = path.join(root, '.env');
const contractsEnvPath = path.join(root, 'contracts', '.env');

const requiredRootVars = [
  'NODE_ENV',
  'PORT',
  'RPC_URL',
  'JWT_SECRET',
  'NAME',
  'SYMBOL',
  'EXT_FEED',
  'NODE_PORT'
];

const requiredContractsVars = [
  'PRIVATE_KEY',
  'ETHEREUM_RPC_URL',
  'BSC_RPC_URL',
  'TOKEN_NAME',
  'TOKEN_SYMBOL',
  'TOKEN_DECIMALS',
  'TOKEN_INITIAL_SUPPLY'
];

function parseEnv(filePath) {
  const map = new Map();
  if (!fs.existsSync(filePath)) return map;
  const lines = fs.readFileSync(filePath, 'utf8').split(/\r?\n/);
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const idx = line.indexOf('=');
    if (idx <= 0) continue;
    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1).trim();
    map.set(key, value);
  }
  return map;
}

function missingVars(envMap, required) {
  return required.filter((k) => !envMap.has(k) || envMap.get(k) === '');
}

function weakSecret(secret) {
  if (!secret) return true;
  const weakPatterns = [/replace/i, /change/i, /please-set/i, /example/i, /dev-secret/i];
  return secret.length < 24 || weakPatterns.some((r) => r.test(secret));
}

function printHeader(title) {
  console.log(`\n=== ${title} ===`);
}

let hasErrors = false;
let hasWarnings = false;

const rootEnv = parseEnv(rootEnvPath);
const contractsEnv = parseEnv(contractsEnvPath);

printHeader('Root .env checks');
if (!fs.existsSync(rootEnvPath)) {
  hasErrors = true;
  console.error('ERROR: Missing .env at repository root.');
} else {
  const miss = missingVars(rootEnv, requiredRootVars);
  if (miss.length) {
    hasErrors = true;
    console.error(`ERROR: Missing required root variables: ${miss.join(', ')}`);
  } else {
    console.log('OK: Required root variables are present.');
  }

  const jwtSecret = rootEnv.get('JWT_SECRET') || '';
  if (weakSecret(jwtSecret)) {
    hasWarnings = true;
    console.warn('WARN: JWT_SECRET appears weak or placeholder-like.');
  } else {
    console.log('OK: JWT_SECRET looks non-placeholder.');
  }
}

printHeader('contracts/.env checks');
if (!fs.existsSync(contractsEnvPath)) {
  hasErrors = true;
  console.error('ERROR: Missing contracts/.env.');
} else {
  const miss = missingVars(contractsEnv, requiredContractsVars);
  if (miss.length) {
    hasErrors = true;
    console.error(`ERROR: Missing required contract variables: ${miss.join(', ')}`);
  } else {
    console.log('OK: Required contracts variables are present.');
  }
}

printHeader('Git tracking checks');
try {
  const tracked = execSync('git ls-files .env contracts/.env', { cwd: root, encoding: 'utf8' })
    .split(/\r?\n/)
    .map((s) => s.trim())
    .filter(Boolean);

  if (tracked.includes('.env')) {
    hasWarnings = true;
    console.warn('WARN: .env is currently tracked by git (recommended: untrack with `git rm --cached .env`).');
  } else {
    console.log('OK: .env is not tracked by git.');
  }

  if (tracked.includes('contracts/.env')) {
    hasWarnings = true;
    console.warn('WARN: contracts/.env is tracked by git (recommended: keep local-only).');
  } else {
    console.log('OK: contracts/.env is not tracked by git.');
  }
} catch (err) {
  hasWarnings = true;
  console.warn(`WARN: Could not inspect git tracking state: ${err.message}`);
}

printHeader('Result');
if (hasErrors) {
  console.error('FAILED: Credential/config audit has blocking issues.');
  process.exitCode = 1;
} else if (hasWarnings) {
  console.warn('PASSED with warnings: No blockers, but improvements are recommended.');
  process.exitCode = 0;
} else {
  console.log('PASSED: Credential/config audit checks are clean.');
  process.exitCode = 0;
}
