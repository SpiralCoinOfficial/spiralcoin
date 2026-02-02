# Docker Deployment Guide

This guide covers deploying SpiralCoin using Docker and Docker Compose.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM
- 20GB+ storage

## Quick Start

### Development Environment

```bash
# Start all services in development mode
docker-compose -f compose.yaml up --build

# Or use the debug configuration
docker-compose -f compose.debug.yaml up
```

### Production Environment

```bash
# Start production services
docker-compose -f docker-compose.prod.yaml up -d

# Or use the full production stack
docker-compose -f docker-compose.prod.full.yaml up -d
```

## Services

### Backend API (Port 5000)
- REST API for blockchain operations
- Wallet management
- Transaction processing

### Daemon (Port 8545)
- Core blockchain node
- RPC interface
- Mining engine

### MarketFeed (Port 4000)
- Real-time market data
- WebSocket support
- External price feeds

### Web Dashboard (Port 3000)
- User interface
- Trading platform
- Monitoring tools

## Configuration

### Environment Variables

Create a `.env` file:

```env
NODE_ENV=production
PORT=5000
RPC_URL=http://daemon:8545
NODE_PORT=4000
EXT_FEED=https://api.example.com/feed
```

### Volume Mounts

Data persistence:
- `./data:/app/data` - Blockchain data
- `./backend_data:/app/backend_data` - API data

## Building Images

### Backend
```bash
docker build -f Dockerfile.backend -t spiralcoin-backend .
```

### Daemon
```bash
docker build -f Dockerfile.daemon -t spiralcoin-daemon .
```

### MarketFeed
```bash
docker build -f Dockerfile.marketfeed -t spiralcoin-marketfeed .
```

### Development
```bash
docker build -f Dockerfile.dev -t spiralcoin:dev .
```

## Monitoring

### Check Service Status
```bash
docker-compose ps
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f daemon
docker-compose logs -f marketfeed
```

### Resource Usage
```bash
docker stats
```

## Troubleshooting

### Services Won't Start
```bash
# Check logs
docker-compose logs

# Rebuild images
docker-compose build --no-cache

# Restart services
docker-compose restart
```

### Port Conflicts
If ports are in use, modify `docker-compose.yaml`:
```yaml
ports:
  - "5001:5000"  # Change host port
```

### Data Persistence Issues
```bash
# Check volume mounts
docker-compose config

# Verify permissions
ls -la ./data ./backend_data
```

## Security

### Production Best Practices
1. Use secrets for sensitive data
2. Enable SSL/TLS
3. Configure firewall rules
4. Regular security updates
5. Monitor logs for anomalies

### Network Isolation
```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true
```

## Scaling

### Horizontal Scaling
```bash
docker-compose up --scale backend=3
```

### Load Balancing
Use Nginx or Traefik for load balancing multiple instances.

## Backup & Recovery

### Backup Data
```bash
# Stop services
docker-compose down

# Backup volumes
tar -czf backup.tar.gz ./data ./backend_data

# Restart services
docker-compose up -d
```

### Restore Data
```bash
# Stop services
docker-compose down

# Restore volumes
tar -xzf backup.tar.gz

# Restart services
docker-compose up -d
```

## Updates

### Rolling Updates
```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

### Zero-Downtime Updates
Use blue-green deployment or rolling updates with orchestration tools.

## References

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/)
- [QUICK_START.md](QUICK_START.md) - Quick start guide
- [DEPLOYMENT_READY.md](DEPLOYMENT_READY.md) - Production deployment
