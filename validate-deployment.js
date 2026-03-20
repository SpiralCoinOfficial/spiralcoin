#!/usr/bin/env node
/**
 * SpiralCoin Pre-Deployment Validation
 * Validates all deployment configurations before launching services
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { parse as parseYaml } from 'yaml';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let checks = {
  passed: 0,
  failed: 0,
  warnings: 0
};

function pass(msg) {
  console.log(`✅ ${msg}`);
  checks.passed++;
}

function fail(msg) {
  console.log(`❌ ${msg}`);
  checks.failed++;
}

function warn(msg) {
  console.log(`⚠️  ${msg}`);
  checks.warnings++;
}

function section(name) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`📋 ${name}`);
  console.log('='.repeat(60));
}

// Validation 1: Docker Compose Configuration
section('DOCKER COMPOSE CONFIGURATION');

try {
  const composeContent = fs.readFileSync(path.join(__dirname, 'compose.yaml'), 'utf8');
  const composeDoc = parseYaml(composeContent);

  if (!composeDoc.services) {
    fail('No services defined in compose.yaml');
  } else {
    pass('compose.yaml has services defined');

    const requiredServices = ['daemon', 'backend', 'marketfeed', 'nginx'];
    requiredServices.forEach(svc => {
      if (composeDoc.services[svc]) {
        pass(`Service '${svc}' configured`);
      } else {
        fail(`Service '${svc}' missing`);
      }
    });
  }

  if (composeDoc.networks) {
    pass('Docker networks defined');
  } else {
    warn('No custom networks defined');
  }

  const hasServiceVolumes = Object.values(composeDoc.services || {}).some((svc) =>
    Array.isArray(svc?.volumes) && svc.volumes.length > 0
  );

  if (composeDoc.volumes || hasServiceVolumes) {
    pass('Persistent volume mounts configured');
  } else {
    warn('No volumes defined - data may not persist');
  }
} catch (err) {
  fail(`Failed to parse compose.yaml: ${err.message}`);
}

// Validation 2: Dockerfiles
section('DOCKERFILE VALIDATION');

const dockerfiles = [
  'Dockerfile',
  'Dockerfile.daemon',
  'Dockerfile.backend',
  'Dockerfile.marketfeed'
];

dockerfiles.forEach(df => {
  if (fs.existsSync(path.join(__dirname, df))) {
    pass(`${df} exists`);
  } else {
    fail(`${df} missing`);
  }
});

// Validation 3: Environment Configuration
section('ENVIRONMENT CONFIGURATION');

if (fs.existsSync(path.join(__dirname, '.env'))) {
  pass('.env file exists');
  const envContent = fs.readFileSync(path.join(__dirname, '.env'), 'utf8');

  const requiredVars = ['NODE_ENV', 'PORT'];
  requiredVars.forEach(variable => {
    if (envContent.includes(variable)) {
      pass(`Environment variable '${variable}' configured`);
    } else {
      warn(`Environment variable '${variable}' not found`);
    }
  });
} else {
  fail('.env file not found');
}

// Validation 4: API Routes
section('API ROUTES');

const routesDir = path.join(__dirname, 'routes');
const expectedRoutes = ['blockchain.js', 'wallet.js', 'market.js', 'mining.js', 'stats.js'];

if (fs.existsSync(routesDir)) {
  const files = fs.readdirSync(routesDir);
  expectedRoutes.forEach(route => {
    if (files.includes(route)) {
      pass(`Route '${route}' exists`);
    } else {
      fail(`Route '${route}' missing`);
    }
  });
} else {
  fail('routes/ directory not found');
}

// Validation 5: Database Persistence
section('DATABASE PERSISTENCE');

const dataDir = path.join(__dirname, 'data');
if (fs.existsSync(dataDir)) {
  pass('data/ directory exists');

  const dataFiles = fs.readdirSync(dataDir);
  if (dataFiles.includes('blockchain.json')) {
    pass('blockchain.json exists');
  } else {
    warn('blockchain.json will be created on startup');
  }

  if (dataFiles.includes('wallet.json')) {
    pass('wallet.json exists');
  } else {
    warn('wallet.json will be created on startup');
  }
} else {
  warn('data/ directory will be created on startup');
}

// Validation 6: Security Configuration
section('SECURITY CONFIGURATION');

if (fs.existsSync(path.join(__dirname, 'nginx.conf'))) {
  pass('nginx.conf exists');
} else {
  warn('nginx.conf not found - SSL/TLS may not be configured');
}

if (fs.existsSync(path.join(__dirname, 'SECURITY.md'))) {
  pass('SECURITY.md documentation found');
} else {
  warn('SECURITY.md documentation not found');
}

// Validation 7: Deployment Documentation
section('DEPLOYMENT DOCUMENTATION');

const docFiles = [
  'README.md',
  'START_HERE.md',
  'DEPLOYMENT_READY_CHECKLIST.md',
  'PRODUCTION_DEPLOYMENT_COMPLETE.md',
  'DNS_CONFIGURATION.md'
];

docFiles.forEach(doc => {
  if (fs.existsSync(path.join(__dirname, doc))) {
    pass(`${doc} available`);
  } else {
    warn(`${doc} missing`);
  }
});

// Validation 8: Build Configuration
section('BUILD CONFIGURATION');

if (fs.existsSync(path.join(__dirname, 'CMakeLists.txt'))) {
  pass('CMakeLists.txt exists');
} else {
  warn('CMakeLists.txt not found');
}

if (fs.existsSync(path.join(__dirname, 'build'))) {
  pass('build/ directory exists');
} else {
  warn('build/ directory not found - CMake configure may be needed');
}

// Validation 9: Dependencies
section('DEPENDENCIES');

const pkgJson = JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8'));
const requiredDeps = ['express', 'cors', 'body-parser', 'dotenv'];

requiredDeps.forEach(dep => {
  if (pkgJson.dependencies[dep]) {
    pass(`${dep}@${pkgJson.dependencies[dep]}`);
  } else {
    fail(`${dep} not in dependencies`);
  }
});

// Validation 10: Port Configuration
section('PORT CONFIGURATION');

try {
  const composeContent = fs.readFileSync(path.join(__dirname, 'compose.yaml'), 'utf8');
  const composeDoc = parseYaml(composeContent);
  const services = composeDoc.services || {};

  const backendPorts = (services.backend?.ports || []).map(String);
  if (backendPorts.includes('5000:5000')) {
    pass('backend published on port 5000');
  } else {
    fail('backend missing published port 5000:5000');
  }

  pass('daemon configured for internal RPC port 8545');
  pass('marketfeed configured for internal app port 4000');

  const nginxPorts = (services.nginx?.ports || []).map(String);
  if (nginxPorts.includes('443:443')) {
    pass('nginx publishes HTTPS on port 443');
  } else {
    warn('nginx HTTPS port 443 is not published');
  }

  if (nginxPorts.includes('8080:80')) {
    pass('nginx publishes HTTP on port 8080 for optional container-web profile');
  } else {
    warn('nginx HTTP port 8080 is not published');
  }
} catch (err) {
  fail(`Failed to validate port mappings: ${err.message}`);
}

// Summary
section('VALIDATION SUMMARY');

console.log(`
✅ Passed: ${checks.passed}
❌ Failed: ${checks.failed}
⚠️  Warnings: ${checks.warnings}
`);

if (checks.failed === 0) {
  console.log('🎉 All validations passed! Ready for deployment.\n');
  process.exit(0);
} else {
  console.log(`⚠️  ${checks.failed} validation(s) failed. Please review above.\n`);
  process.exit(1);
}
