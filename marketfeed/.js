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

server.listen({NODE_PORT}, '127.0.0.1', () => {
  console.log("[marketfeed] listening on http://127.0.0.1:${NODE_PORT}");
});

// start the poll loop
setInterval(pollLoop, POLL_INTERVAL_MS);
pollLoop();
