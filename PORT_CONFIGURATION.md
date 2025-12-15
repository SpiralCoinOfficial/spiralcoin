# SpiralCoin Port Configuration Guide

## Summary of All Ports

| Service | Port | Protocol | Purpose | Environment Variable |
|---------|------|----------|---------|---------------------|
| SSH | 22 | TCP | Remote access (standard) | SSH_PORT |
| API Server | 5000 | TCP/HTTP | REST API & WebSocket | PORT |
| Market Feed | 4000 | TCP/HTTP | Market data & WebSocket | MARKETFEED_PORT |
| RPC Daemon | 8545 | TCP/HTTP | Blockchain RPC interface | RPC_PORT |
| Node Inspector | 9229 | TCP | Debug API server (dev only) | - |
| Node Inspector | 9230 | TCP | Debug market feed (dev only) | - |

## Configuration Files

### .env (Local Development)
```env
PORT=5000                          # API Server port
MARKETFEED_PORT=4000              # Market Feed port
SSH_PORT=22                        # SSH port
NODE_ENV=production               # Environment mode
```

### compose.yaml (Production)
- **spiralcoin-api**: Exposed on port 5000
- **spiralcoin-marketfeed**: Exposed on port 4000
- **Network**: spiralcoin-network (internal bridge)

### compose.debug.yaml (Development)
- **spiralcoin-api**: Exposed on ports 5000, 9229 (debug)
- **spiralcoin-marketfeed**: Exposed on ports 4000, 9230 (debug)
- **Network**: spiralcoin-network (internal bridge)

### Deployment (deploy_trading_platform.sh)
- **SSH Port**: 22 (configurable via SSH_PORT env var)
- **Nginx**: Listens on 80 (HTTP redirect) and 443 (HTTPS)
- **API Proxy**: /api/ → http://127.0.0.1:5000
- **Feed Proxy**: /feed/ → http://127.0.0.1:4000
- **WebSocket**: /ws → ws://127.0.0.1:4000

## SSH Configuration

### Security Settings (enable_root_ssh.sh)
- **Port**: 22 (standard, secure default)
- **PermitRootLogin**: yes (enabled)
- **PasswordAuthentication**: yes (enabled)
- **Protocol**: 2 (SSH v2 only)

### Connection Command
```bash
ssh -p 22 root@your-server-ip
# or (if port is standard)
ssh root@your-server-ip
```

### Firewall Rules
```bash
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw --force enable
```

## Docker Network Architecture

```
┌─────────────────────────────────────────┐
│       spiralcoin-network (bridge)       │
│                                         │
│  ┌──────────────┐    ┌──────────────┐ │
│  │ spiralcoin-  │    │ spiralcoin-  │ │
│  │     api      │◄──►│  marketfeed  │ │
│  │ :5000        │    │ :4000        │ │
│  └──────────────┘    └──────────────┘ │
│                                         │
└─────────────────────────────────────────┘
         ▲                 ▲
         │                 │
      host:5000        host:4000
```

## Nginx Reverse Proxy Setup

```nginx
# Listens on ports 80 (HTTP) and 443 (HTTPS)
# Proxies to internal services:

location /api/ {
    proxy_pass http://127.0.0.1:5000;
}

location /feed/ {
    proxy_pass http://127.0.0.1:4000;
}

location /ws {
    proxy_pass http://127.0.0.1:4000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

## Testing Connectivity

### Local Testing
```bash
# Test API Server
curl http://127.0.0.1:5000/api/blockchain

# Test Market Feed
curl http://127.0.0.1:4000/api/feed

# Test WebSocket
websocat ws://127.0.0.1:4000/
```

### Remote Testing (after deployment)
```bash
# Test via HTTPS
curl https://your-domain.com/api/blockchain

# Test Market Feed
curl https://your-domain.com/feed/api/feed

# Test WebSocket
wscat -c wss://your-domain.com/ws
```

## Port Forwarding (if behind NAT)

```bash
# Forward external port 5000 to internal 5000
ssh -L 5000:127.0.0.1:5000 user@remote-server

# Forward external port 4000 to internal 4000
ssh -L 4000:127.0.0.1:4000 user@remote-server
```

## Environment Variables

Set these in `.env` or shell before running services:

```bash
# Service Ports
export PORT=5000
export MARKETFEED_PORT=4000
export RPC_PORT=8545
export SSH_PORT=22

# Service URLs
export RPC_URL="http://127.0.0.1:8545"
export EXT_FEED="http://127.0.0.1:5000/api/market/feed"

# Environment
export NODE_ENV=production
```

## Troubleshooting

### Port Already in Use
```bash
# Find process using port
sudo lsof -i :5000
sudo netstat -tlnp | grep :5000

# Kill process (if safe)
sudo kill -9 <PID>
```

### Cannot Connect to API
1. Check service is running: `docker ps` or `systemctl status`
2. Check port is open: `netstat -tlnp` or `sudo ss -tlnp`
3. Check firewall: `sudo ufw status`
4. Check DNS resolution (if using domain)

### SSH Access Denied
1. Verify SSH port: `sudo grep "^Port" /etc/ssh/sshd_config`
2. Restart SSH: `sudo systemctl restart sshd`
3. Check SSH is enabled: `sudo systemctl enable sshd`
4. Verify firewall allows port 22: `sudo ufw status`

### WebSocket Connection Fails
1. Check Node.js service is running
2. Verify proxy configuration in Nginx
3. Check WebSocket upgrade headers are set
4. Ensure SSL/TLS is properly configured

## Security Best Practices

1. **Change default passwords** after first login
2. **Use SSH keys** instead of password authentication
3. **Restrict SSH access** to trusted IPs via firewall
4. **Use HTTPS/TLS** for all production connections
5. **Enable firewall** and only allow necessary ports
6. **Use strong passwords** if password auth is enabled
7. **Monitor logs** for unauthorized access attempts
8. **Disable root SSH** if not needed (set PermitRootLogin no)

## Restarting Services

### Docker Services
```bash
# Restart API server
docker restart spiralcoin-api

# Restart Market Feed
docker restart spiralcoin-marketfeed

# Restart all services
docker-compose restart
```

### Systemd Services
```bash
# Restart SSH
sudo systemctl restart sshd

# Restart SpiralCoin daemon
sudo systemctl restart spiralcoind

# Restart Market Feed
sudo systemctl restart spiralcoin-marketfeed

# View logs
sudo journalctl -u spiralcoind -f
sudo journalctl -u spiralcoin-marketfeed -f
```

## Rate Limiting

The API server implements rate limiting:
- **Max requests**: 100 per IP
- **Time window**: 15 minutes
- **Apply to**: All endpoints (configurable)

Configure in `server.js`:
```javascript
const rateLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,  // 15 minutes
    max: 100,                   // limit each IP to 100 requests per windowMs
});
```
