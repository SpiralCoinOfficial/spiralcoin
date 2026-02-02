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

function warn(msg) {
  console.log(`WARN: ${msg}`);
}

try {
  const raw = fs.readFileSync(composePath, 'utf8');
  const doc = parse(raw);
  if (!doc || typeof doc !== 'object') fail('compose.yaml parsed as empty');

  const services = doc.services || {};
  
  // Check for core services (web is optional with nginx profile)
  const requiredServices = ['daemon', 'backend', 'marketfeed'];
  for (const svc of requiredServices) {
    if (!services[svc]) {
      fail(`service ${svc} missing`);
    } else {
      ok(`service ${svc} present`);
    }
  }

  // Check for web/nginx service (one should be present)
  if (!services['web'] && !services['nginx']) {
    warn('no web or nginx service defined - using external web server?');
  } else {
    ok('web frontend service configured');
  }

  // Check backend port (required for API access)
  const backend = services['backend'];
  if (backend) {
    const ports = backend.ports || [];
    if (ports.some(p => p.includes('5000'))) {
      ok('backend API port 5000 exposed');
    } else {
      warn('backend port 5000 not exposed to host (internal only)');
    }
  }

  // Check if daemon port is exposed (optional for security)
  const daemon = services['daemon'];
  if (daemon) {
    const ports = daemon.ports || [];
    if (ports.some(p => p.includes('8545'))) {
      warn('daemon RPC port 8545 exposed (consider keeping internal for security)');
    } else {
      ok('daemon RPC port kept internal (secure)');
    }
  }

  // Check if marketfeed port is exposed (optional)
  const marketfeed = services['marketfeed'];
  if (marketfeed) {
    const ports = marketfeed.ports || [];
    if (ports.some(p => p.includes('4000'))) {
      ok('marketfeed port 4000 exposed');
    } else {
      warn('marketfeed port 4000 not exposed to host (internal only)');
    }
  }

  ok('compose.yaml structure validated');
} catch (err) {
  console.error('ERROR:', err.message || err);
  process.exitCode = 1;
}
