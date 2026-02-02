# SpiralCoin Development Agents

This file documents the AI agents and automation used in the SpiralCoin development workflow.

## Overview

SpiralCoin development utilizes various automation tools and scripts to streamline deployment, testing, and maintenance tasks.

## Automation Scripts

### Build Automation
- `AUTO_BUILD.bat` / `AUTO_BUILD.ps1` - Automated build process for Windows
- `AUTO_EXECUTE.bat` - Execute built binaries automatically
- `AUTO_RUN_ALL.ps1` - Complete automation workflow

### Deployment Automation
- `AUTO_SETUP_AND_PUBLISH.ps1` - Setup and publish workflow
- `DEPLOY_ALL_PROD.ps1` - Production deployment
- `auto-deploy.ps1` - General deployment automation

### Testing & Validation
- `scripts/validate-compose.js` - Docker Compose validation
- `e2e-test.js` - End-to-end testing
- `validate-deployment.js` - Deployment verification

### Scanning & Security
- `EXECUTE_SCAN_NOW.bat` - Run security scans
- `FINAL_SCAN.ps1` - Comprehensive final scan
- `commit-and-scan.bat` - Scan before commit

## CI/CD Integration

The project includes GitHub Actions workflows for:
- Automated builds
- Security scanning
- Deployment to production

## Usage

To run automated tasks:

```bash
# Windows
./AUTO_RUN_ALL.ps1

# Linux/WSL
./scripts/automated-workflow.sh
```

## Contributing

When adding new automation:
1. Document the script purpose
2. Add error handling
3. Include logging
4. Test thoroughly
5. Update this file
