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

  // Required services matching actual compose.yaml
  const requiredServices = ['daemon', 'backend', 'marketfeed', 'nginx'];
  for (const svc of requiredServices) {
    if (!services[svc]) fail(`service ${svc} missing`);
  }

  // Only check ports that are actually host-mapped in compose.yaml
  const ports = {
    backend: '5000:5000',
    nginx: '443:443'
  };

  for (const [svc, expected] of Object.entries(ports)) {
    const svcDef = services[svc];
    if (!svcDef) continue;
    const p = (svcDef.ports || []).map(String);
    if (!p.includes(expected)) fail(`service ${svc} missing port ${expected}`);
  }

  ok('compose.yaml structure and ports look good');
} catch (err) {
  console.error('ERROR:', err.message || err);
  process.exitCode = 1;
}
