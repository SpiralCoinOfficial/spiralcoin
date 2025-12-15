#!/bin/bash
set -e
echo "[*] Installing SpiralCoin Market Feed + WebSocket proxy"

BASE="${BASE:-~/spiralcoin}"
MF_DIR="$BASE/marketfeed"
RPC_HOST="${RPC_HOST:-127.0.0.1}"
RPC_PORT="${RPC_PORT:-8545}"
RPC_URL="http://${RPC_HOST}:${RPC_PORT}/rpc"
EXT_FEED="${EXT_FEED:-http://127.0.0.1:5000/api/market/feed}"
NODE_PORT="${NODE_PORT:-4000}"

# 1) Create folder
mkdir -p "$MF_DIR"
cd "$MF_DIR"

# 2) Create package.json
cat > package.json <<'JSON'
{
  "name": "spiralcoin-marketfeed",
  "version": "1.0.0",
  "description": "Market feed + websocket proxy for SpiralCoin",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "axios": "^1.4.0",
    "ws": "^8.13.0",
    "express": "^4.18.2"
  }
}
JSON

# 3) Create server.js
cat > server.js <<'JS'
/*
  SpiralCoin Market Feed + WebSocket proxy
  - polls local RPC for getdqve
  - polls external feed at EXT_FEED
  - exposes /api/feed and websocket broadcast
*/
const express = require('express');
const axios = require('axios');
const WebSocket = require('ws');
const http = require('http');

const RPC_URL = process.env.RPC_URL || '${RPC_URL}';
const EXT_FEED = process.env.EXT_FEED || '${EXT_FEED}';
const POLL_INTERVAL_MS = 3000;

const app = express();
app.use(express.json());

let latest = {
  timestamp: new Date().toISOString(),
  dqve: null,
  rpc_raw: null,
  external_feed: null
};

// Helper: poll local RPC for getdqve and getwalletinfo
async function pollRPC() {
  try {
    const dqveReq = await axios.post(RPC_URL, { id:1, method: "getdqve", params: [] }, { timeout: 3000 });
    const walletReq = await axios.post(RPC_URL, { id:1, method: "getwalletinfo", params: [] }, { timeout: 3000 });
    latest.rpc_raw = { dqve: dqveReq.data, wallet: walletReq.data };
    latest.dqve = dqveReq.data.result || dqveReq.data;
  } catch (err) {
    latest.rpc_raw = { error: "rpc_poll_failed", message: err.message };
    latest.dqve = null;
    console.error("[marketfeed] RPC poll error:", err.message);
  }
}

// Helper: poll external feed (if available)
async function pollExternalFeed() {
  try {
    const res = await axios.get(EXT_FEED, { timeout: 3000 });
    latest.external_feed = res.data;
  } catch (err) {
    latest.external_feed = { error: "external_unreachable", message: err.message };
    // no noisy console here — external feed may often be offline
  }
  latest.timestamp = new Date().toISOString();
}

// Periodic poll loop
async function pollLoop() {
  await Promise.allSettled([pollRPC(), pollExternalFeed()]);
  // broadcast to WS clients
  broadcast(JSON.stringify({ type: "update", data: latest, ts: new Date().toISOString() }));
}

// HTTP endpoints
app.get('/api/feed', (req, res) => {
  res.json({ ok: true, latest });
});
app.get('/api/dqve', async (req, res) => {
  // forward to RPC if possible
  try {
    const r = await axios.post(RPC_URL, { id:1, method: "getdqve", params: [] }, { timeout: 3000 });
    return res.json(r.data);
  } catch (err) {
    return res.status(500).json({ error: "rpc_error", message: err.message, cached: latest.dqve });
  }
});

// create server + ws
const server = http.createServer(app);
const wss = new WebSocket.Server({ server, path: '/' });

function broadcast(msg) {
  wss.clients.forEach((c) => {
    if (c.readyState === WebSocket.OPEN) {
      c.send(msg);
    }
  });
}

wss.on('connection', (ws, req) => {
  console.log('[marketfeed] ws client connected:', req.socket.remoteAddress);
  // send current snapshot on connect
  ws.send(JSON.stringify({ type: 'welcome', data: latest, ts: new Date().toISOString() }));
  ws.on('message', (m) => {
    // simple ping/pong or future control commands
    try {
      const p = JSON.parse(m.toString());
      if (p && p.type === 'ping') ws.send(JSON.stringify({ type: 'pong', ts: new Date().toISOString() }));
    } catch(e){}
  });
});

server.listen(${NODE_PORT}, '127.0.0.1', () => {
  console.log("[marketfeed] listening on http://127.0.0.1:${NODE_PORT}");
});

// start the poll loop
setInterval(pollLoop, POLL_INTERVAL_MS);
pollLoop();
JS

# 4) Install Node (light) if not present & npm modules
if ! command -v node >/dev/null 2>&1; then
  echo "[*] Node.js not found — installing Node 20 LTS..."
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

# install npm deps
cd "$MF_DIR"
npm install --production

# 5) Create systemd service to run it
MF_SERVICE="/etc/systemd/system/spiralcoin-marketfeed.service"
sudo tee "$MF_SERVICE" >/dev/null <<EOF
[Unit]
Description=SpiralCoin Market Feed + WebSocket proxy
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$MF_DIR
Environment=RPC_URL=${RPC_URL}
Environment=EXT_FEED=${EXT_FEED}
ExecStart=/usr/bin/node $MF_DIR/server.js
Restart=always
RestartSec=3
LimitNOFILE=8192

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable spiralcoin-marketfeed
sudo systemctl start spiralcoin-marketfeed

# 6) Configure nginx to proxy /api/feed and /ws to Node (append to existing site config)
NGX_CONF="/etc/nginx/sites-available/spiralcoin"
if [ -f "$NGX_CONF" ]; then
  echo "[*] Updating existing nginx config: $NGX_CONF"
  sudo sed -n '1,200p' "$NGX_CONF" > /tmp/spiralcoin.nginx.tmp || true
else
  sudo tee "$NGX_CONF" >/dev/null <<'NGX_DEFAULT'
server {
    listen 80;
    server_name spiralcoin.net www.spiralcoin.net;
    root /var/www/html/spiralcoin;
    index index.html;
    location / { try_files $uri /index.html; }
}
NGX_DEFAULT
fi

# Ensure /api/feed and /ws locations exist (idempotent append)
sudo bash -c "grep -q 'location /api/feed' $NGX_CONF || cat >> $NGX_CONF <<'NGX_APPEND'

    # Marketfeed API proxy
    location /api/feed {
        proxy_pass http://127.0.0.1:${NODE_PORT}/api/feed;
        proxy_set_header Host \$host;
        proxy_http_version 1.1;
    }

    location /api/dqve {
        proxy_pass http://127.0.0.1:${NODE_PORT}/api/dqve;
        proxy_set_header Host \$host;
        proxy_http_version 1.1;
    }

    # WebSocket proxy for live updates (path '/ws' on nginx -> '/' on node)
    location /ws {
        proxy_pass http://127.0.0.1:${NODE_PORT}/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
        proxy_set_header Host \$host;
    }
NGX_APPEND"

sudo nginx -t
sudo systemctl reload nginx

echo "[*] Marketfeed installed and started."
echo "HTTP API: http://127.0.0.1:${NODE_PORT}/api/feed  (proxied at /api/feed)"
echo "WebSocket (local): ws://127.0.0.1:${NODE_PORT}/"
echo "WebSocket (via nginx): ws://<your-domain-or-ip>/ws"
echo "Check service logs: sudo journalctl -u spiralcoin-marketfeed -f"
