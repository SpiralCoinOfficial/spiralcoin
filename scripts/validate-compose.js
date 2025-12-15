#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parse } from 'yaml';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const composePath = path.resolve(__dirname, '..', 'compose.yaml');

function fail(msg) {
  console.error(`FAIL: ${msg}`);
  process.exitCode = 1;
}

function ok(msg) {
  console.log(`OK: ${msg}`);
}

try {
  const raw = fs.readFileSync(composePath, 'utf8');
  const doc = parse(raw);
  if (!doc || typeof doc !== 'object') fail('compose.yaml parsed as empty');

  const services = doc.services || {};
  const requiredServices = ['daemon', 'backend', 'marketfeed', 'web'];
  for (const svc of requiredServices) {
    if (!services[svc]) fail(`service ${svc} missing`);
  }

  const ports = {
    daemon: '8545:8545',
    backend: '5000:5000',
    marketfeed: '4000:4000',
    web: '3000:80'
  };

  for (const [svc, expected] of Object.entries(ports)) {
    const svcDef = services[svc];
    if (!svcDef) continue;
    const p = svcDef.ports || [];
    if (!p.includes(expected)) fail(`service ${svc} missing port ${expected}`);
  }

  ok('compose.yaml structure and ports look good');
} catch (err) {
  console.error('ERROR:', err.message || err);
  process.exitCode = 1;
}
