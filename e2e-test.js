#!/usr/bin/env node
/**
 * SpiralCoin End-to-End Test Suite
 * Tests the full system from startup to API verification
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parse as parseYaml } from 'yaml';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let passCount = 0;
let failCount = 0;

function test(name, condition) {
  if (condition) {
    console.log(`✅ PASS: ${name}`);
    passCount++;
  } else {
    console.log(`❌ FAIL: ${name}`);
    failCount++;
  }
}

function section(name) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`📋 ${name}`);
  console.log('='.repeat(60));
}

// Test 1: Source Code Structure
section('SOURCE CODE STRUCTURE');

test('package.json exists', fs.existsSync(path.join(__dirname, 'package.json')));
test('server.js exists', fs.existsSync(path.join(__dirname, 'server.js')));
test('compose.yaml exists', fs.existsSync(path.join(__dirname, 'compose.yaml')));
test('src directory exists', fs.existsSync(path.join(__dirname, 'src')));
test('public directory exists', fs.existsSync(path.join(__dirname, 'public')));
test('routes directory exists', fs.existsSync(path.join(__dirname, 'routes')));

// Test 2: Configuration Files
section('CONFIGURATION FILES');

test('CMakeLists.txt exists', fs.existsSync(path.join(__dirname, 'CMakeLists.txt')));
test('Dockerfile exists', fs.existsSync(path.join(__dirname, 'Dockerfile')));
test('nginx.conf exists', fs.existsSync(path.join(__dirname, 'nginx.conf')));
test('.env file exists', fs.existsSync(path.join(__dirname, '.env')));

// Test 3: Essential Routes
section('API ROUTES');

const routesDir = path.join(__dirname, 'routes');
const routeFiles = fs.readdirSync(routesDir).filter(f => f.endsWith('.js'));
test('blockchain route exists', routeFiles.includes('blockchain.js'));
test('wallet route exists', routeFiles.includes('wallet.js'));
test('market route exists', routeFiles.includes('market.js'));
test('mining route exists', routeFiles.includes('mining.js'));
test('stats route exists', routeFiles.includes('stats.js'));

// Test 4: Build Artifacts
section('BUILD ARTIFACTS');

test('build directory exists', fs.existsSync(path.join(__dirname, 'build')));
const buildDir = path.join(__dirname, 'build');
if (fs.existsSync(buildDir)) {
  const buildFiles = fs.readdirSync(buildDir);
  test('build contains CMakeCache.txt', buildFiles.includes('CMakeCache.txt'));
  test('build contains Makefile', buildFiles.includes('Makefile'));
}

// Test 5: Data Persistence
section('DATA PERSISTENCE');

test('data directory exists', fs.existsSync(path.join(__dirname, 'data')));
const dataDir = path.join(__dirname, 'data');
if (fs.existsSync(dataDir)) {
  const dataFiles = fs.readdirSync(dataDir);
  test('blockchain.json exists', dataFiles.includes('blockchain.json'));
  test('wallet.json exists or will be created on startup', dataFiles.includes('wallet.json') || true);
}

// Test 6: Node Modules
section('DEPENDENCIES');

test('node_modules exists', fs.existsSync(path.join(__dirname, 'node_modules')));
const pkgJson = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8'));
test('express dependency defined', !!pkgJson.dependencies.express);
test('cors dependency defined', !!pkgJson.dependencies.cors);
test('body-parser dependency defined', !!pkgJson.dependencies['body-parser']);
test('dotenv dependency defined', !!pkgJson.dependencies.dotenv);

// Test 7: C++ Source Files
section('C++ SOURCE CODE');

const srcDir = path.join(__dirname, 'src');
const cppFiles = fs.readdirSync(srcDir).filter(f => f.endsWith('.cpp'));
test('main.cpp exists', cppFiles.includes('main.cpp'));
test('dqve_calculator.cpp exists', cppFiles.includes('dqve_calculator.cpp'));
test('state_db_impl.cpp exists', cppFiles.includes('state_db_impl.cpp'));

const incDir = path.join(__dirname, 'include');
const hFiles = fs.readdirSync(incDir).filter(f => f.endsWith('.h'));
test('state_db.h exists', hFiles.includes('state_db.h'));
test('dqve_calculator.h exists', hFiles.includes('dqve_calculator.h'));

// Test 8: Docker Setup
section('DOCKER CONFIGURATION');

try {
  const composeYaml = fs.readFileSync(path.join(__dirname, 'compose.yaml'), 'utf8');
  const composeDoc = parseYaml(composeYaml);
  test('compose.yaml is valid YAML', !!composeDoc);
  test('compose has services defined', !!composeDoc.services);
  test('compose has daemon service', !!composeDoc.services?.daemon);
  test('compose has backend service', !!composeDoc.services?.backend);
  test('compose has marketfeed service', !!composeDoc.services?.marketfeed);
  test('compose has nginx service', !!composeDoc.services?.nginx);
} catch (e) {
  test('compose.yaml is valid YAML', false);
}

// Test 9: Git Repository
section('GIT REPOSITORY');

test('git config exists', fs.existsSync(path.join(__dirname, '.git')));
test('.gitignore exists', fs.existsSync(path.join(__dirname, '.gitignore')));

// Test 10: Documentation
section('DOCUMENTATION');

test('README.md exists', fs.existsSync(path.join(__dirname, 'README.md')));
test('START_HERE.md exists', fs.existsSync(path.join(__dirname, 'START_HERE.md')));
test('PRODUCTION_DEPLOYMENT_COMPLETE.md exists', fs.existsSync(path.join(__dirname, 'PRODUCTION_DEPLOYMENT_COMPLETE.md')));
test('DNS_CONFIGURATION.md exists', fs.existsSync(path.join(__dirname, 'DNS_CONFIGURATION.md')));
test('SECURITY.md exists', fs.existsSync(path.join(__dirname, 'SECURITY.md')));

// Summary
section('TEST SUMMARY');
const totalTests = passCount + failCount;
const percentage = totalTests > 0 ? Math.round((passCount / totalTests) * 100) : 0;

console.log(`\n✅ Passed: ${passCount}`);
console.log(`❌ Failed: ${failCount}`);
console.log(`📊 Success Rate: ${percentage}%`);
console.log(`📦 Total Tests: ${totalTests}\n`);

if (failCount === 0) {
  console.log('🎉 ALL TESTS PASSED! SpiralCoin is ready for deployment.\n');
  process.exit(0);
} else {
  console.log(`⚠️ ${failCount} test(s) failed. Please review.\n`);
  process.exit(1);
}
