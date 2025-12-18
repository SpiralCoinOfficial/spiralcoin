# Operator Guide

## Overview

This guide covers running, monitoring, backing up, and upgrading SpiralCoin nodes in production.

## Requirements

- CPU/RAM: per [DEPLOYMENT_READY.md](DEPLOYMENT_READY.md)
- Ports: RPC 8545 (HTTP), optional P2P

## Run

- Docker (recommended): see [DEPLOYMENT_READY.md](DEPLOYMENT_READY.md)
- Native: follow [BUILD_GUIDE.md](BUILD_GUIDE.md)

## Monitoring

- Health checks: RPC `getblockcount` on `/rpc`.
- Logs: use `docker logs` or system logs; see `scripts/remote-docker-logs.ps1`.
- Metrics: export basic metrics via backend endpoints (if enabled).

## Backups & Recovery

- Persist data directory; snapshot before upgrades.
- To restore, stop node, replace data directory with snapshot, start node.

## Upgrades

- Review release notes, verify checksums/signatures, snapshot data, then deploy.
