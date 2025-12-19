import bodyParser from "body-parser";
import cors from "cors";
import dotenv from "dotenv";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import * as crypto from "node:crypto";
import { promises as fs } from "node:fs";
import path from "path";
import { fetch as undiciFetch } from "undici";
import { fileURLToPath } from "url";

import { blockchainRouter } from "./routes/blockchain.js";
import { marketRouter } from "./routes/market.js";
import { miningRouter } from "./routes/mining.js";
import { statsRouter } from "./routes/stats.js";
import { supplyRouter } from "./routes/supply.js";
import { walletRouter } from "./routes/wallet.js";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 5000;
// Ensure fetch is available on older Node.js versions
const fetch = globalThis.fetch ?? undiciFetch;

// Restrict CORS to known origins (dev localhost and production domains)
const allowedOrigins = [
  /^https?:\/\/localhost(?::\d+)?$/i,
  /^https?:\/\/127\.0\.0\.1(?::\d+)?$/i,
  /^https?:\/\/(www\.)?spiralcoin\.net$/i
];
app.use(cors({
  origin: (origin, callback) => {
    if (!origin) return callback(null, true); // same-origin or non-browser requests
    const ok = allowedOrigins.some((re) => re.test(origin));
    return ok ? callback(null, true) : callback(new Error("Not allowed by CORS"));
  },
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: false
}));
app.use(bodyParser.json());
app.use(helmet());
app.use(helmet.hsts({ maxAge: 15552000 }));

// Basic rate limiter
const limiter = rateLimit({ windowMs: 60 * 1000, max: 120 });
app.use(limiter);

// Global blockchain and pending transactions
export let chain = [];
export let pendingTransactions = [];

// Genesis block
function createGenesisBlock() {
    const block = {
        index: 0,
        timestamp: Date.now(),
        transactions: [],
        nonce: 0,
        previousHash: "0"
    };
    block.hash = crypto.createHash("sha256").update(JSON.stringify(block)).digest("hex");
    return block;
}
if (chain.length === 0) chain.push(createGenesisBlock());

// Serve frontend
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dataDir = path.join(__dirname, "data");

app.use(express.static(path.join(__dirname, "public")));
app.get("/", (req, res) => {
    res.sendFile(path.join(__dirname, "public/index.html"));
});
app.get('/trading_platform.html', (req, res) => {
  res.sendFile(path.join(__dirname, 'trading_platform.html'));
});
// Fix case variants and friendly path
app.get('/Trading_platform.html', (req, res) => {
  res.redirect(301, '/trading_platform.html');
});
app.get('/trading', (req, res) => {
  res.redirect(302, '/trading_platform.html');
});

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'healthy', ts: new Date().toISOString() });
});

// System status (moved off /api/stats to avoid shadowing statsRouter)
app.get('/api/system', (_req, res) => {
  res.json({
    ok: true,
    uptime: process.uptime(),
    node: process.version,
    ts: new Date().toISOString()
  });
});

// Live quotes aggregator: SPRC from local API, BTC/ETH/USDT from CoinGecko
app.get('/api/market/quotes', async (req, res) => {
  try {
    const coingeckoUrl = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,tether&vs_currencies=usd&include_24hr_change=true';
    const selfPort = req.socket?.localPort || PORT;
    const sprcUrl = `http://127.0.0.1:${selfPort}/api/market/price`;
    const [cgResp, sprcResp] = await Promise.all([
      fetch(coingeckoUrl, { cache: 'no-store' }),
      fetch(sprcUrl, { cache: 'no-store' })
    ]);
    const cgJson = await cgResp.json().catch(() => ({}));
    const sprcJson = await sprcResp.json().catch(() => ({}));

    const data = {
      SPRC: { usd: typeof sprcJson.price === 'number' ? sprcJson.price : null, usd_24h_change: null },
      BTC: { usd: cgJson?.bitcoin?.usd ?? null, usd_24h_change: cgJson?.bitcoin?.usd_24h_change ?? null },
      ETH: { usd: cgJson?.ethereum?.usd ?? null, usd_24h_change: cgJson?.ethereum?.usd_24h_change ?? null },
      USDT: { usd: cgJson?.tether?.usd ?? null, usd_24h_change: cgJson?.tether?.usd_24h_change ?? null },
      ts: new Date().toISOString()
    };
    res.json(data);
  } catch (err) {
    res.status(502).json({ error: 'Failed to load quotes', details: err?.message || String(err) });
  }
});

// Routes
app.use("/api/market", marketRouter);
app.use("/api/blockchain", blockchainRouter);
app.use("/api/mining", miningRouter);
app.use("/api/stats", statsRouter);
app.use("/api/wallet", walletRouter);
app.use("/api/supply", supplyRouter);

// ---- Simple auth (demo) with basic persistence and refresh tokens ----
const users = new Map(); // email -> { salt, hash, created }
const refreshTokens = new Map(); // token -> { sub, expMs }

async function safeReadJson(p) {
  try {
    const raw = await fs.readFile(p, "utf8");
    return JSON.parse(raw);
  } catch { return null; }
}

async function safeWriteJson(p, obj) {
  try {
    await fs.mkdir(path.dirname(p), { recursive: true });
    await fs.writeFile(p, JSON.stringify(obj, null, 2), "utf8");
  } catch {}
}

const usersPath = path.join(dataDir, "users.json");
const refreshPath = path.join(dataDir, "refresh_tokens.json");

async function loadAuthState() {
  const u = await safeReadJson(usersPath);
  if (u && typeof u === 'object') {
    for (const [email, rec] of Object.entries(u)) users.set(email, rec);
  }
  const r = await safeReadJson(refreshPath);
  if (r && typeof r === 'object') {
    for (const [token, value] of Object.entries(r)) refreshTokens.set(token, value);
  }
}

async function persistUsers() {
  const obj = Object.fromEntries(users.entries());
  await safeWriteJson(usersPath, obj);
}

async function persistRefreshTokens() {
  const obj = Object.fromEntries(refreshTokens.entries());
  await safeWriteJson(refreshPath, obj);
}

function pbkdf2Hash(password, salt) {
  return crypto.pbkdf2Sync(password, salt, 100000, 32, 'sha256').toString('hex');
}
function signToken(payload, secret) {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const signature = crypto.createHmac('sha256', secret).update(`${header}.${body}`).digest('base64url');
  return `${header}.${body}.${signature}`;
}
function verifyToken(token, secret) {
  try {
    const [header, body, signature] = token.split('.');
    const expected = crypto.createHmac('sha256', secret).update(`${header}.${body}`).digest('base64url');
    if (signature !== expected) return null;
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
    if (typeof payload.exp === 'number' && Date.now() >= payload.exp) return null;
    return payload;
  } catch { return null; }
}
const JWT_SECRET = process.env.JWT_SECRET || 'CHANGE_ME_DEV_SECRET';
const ACCESS_TTL = 30 * 60 * 1000; // 30 minutes
const REFRESH_TTL = 7 * 24 * 60 * 60 * 1000; // 7 days

await loadAuthState();

app.post('/api/auth/signup', (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) return res.status(400).json({ error: 'Email and password required' });
  if (users.has(email)) return res.status(400).json({ error: 'Account already exists' });
  const salt = crypto.randomBytes(16).toString('hex');
  const hash = pbkdf2Hash(password, salt);
  users.set(email, { salt, hash, created: new Date().toISOString() });
  persistUsers();
  res.json({ ok: true });
});

app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body || {};
  const rec = users.get(email);
  if (!rec) return res.status(400).json({ error: 'Invalid credentials' });
  const hash = pbkdf2Hash(password, rec.salt);
  if (hash !== rec.hash) return res.status(400).json({ error: 'Invalid credentials' });
  const now = Date.now();
  const access = signToken({ sub: email, ts: now, exp: now + ACCESS_TTL }, JWT_SECRET);
  const refresh = crypto.randomBytes(32).toString('hex');
  refreshTokens.set(refresh, { sub: email, expMs: now + REFRESH_TTL });
  persistRefreshTokens();
  res.json({ token: access, refreshToken: refresh, expiresInMs: ACCESS_TTL });
});

app.get('/api/account', (req, res) => {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  const payload = token ? verifyToken(token, JWT_SECRET) : null;
  if (!payload) return res.status(401).json({ error: 'Unauthorized' });
  res.json({ email: payload.sub, created: users.has(payload.sub) });
});

app.post('/api/auth/refresh', (req, res) => {
  const { refreshToken } = req.body || {};
  if (!refreshToken) return res.status(400).json({ error: 'Missing refresh token' });
  const rec = refreshTokens.get(refreshToken);
  if (!rec) return res.status(401).json({ error: 'Invalid refresh token' });
  if (Date.now() >= rec.expMs) {
    refreshTokens.delete(refreshToken);
    persistRefreshTokens();
    return res.status(401).json({ error: 'Expired refresh token' });
  }
  const now = Date.now();
  const access = signToken({ sub: rec.sub, ts: now, exp: now + ACCESS_TTL }, JWT_SECRET);
  res.json({ token: access, expiresInMs: ACCESS_TTL });
});

app.post('/api/auth/logout', (req, res) => {
  const { refreshToken } = req.body || {};
  if (refreshToken && refreshTokens.has(refreshToken)) {
    refreshTokens.delete(refreshToken);
    persistRefreshTokens();
  }
  res.json({ ok: true });
});

// Global error handler
app.use((err, req, res, next) => {
    console.error("Unhandled error:", err);
    res.status(500).json({ success: false, error: err.message });
});

// Harden process error handling
process.on('uncaughtException', (err) => {
  console.error('uncaughtException:', err);
});
process.on('unhandledRejection', (reason) => {
  console.error('unhandledRejection:', reason);
});

// Start server with port fallback if already in use
function startServer(port, attempts = 0) {
  try {
    const server = app.listen(port, () => console.log(`✅ SpiralCoin backend running on port ${port}`));
    server.on('error', (err) => {
      if (err && err.code === 'EADDRINUSE' && attempts < 5) {
        const nextPort = Number(port) + 1;
        console.warn(`⚠️ Port ${port} in use; retrying on ${nextPort}...`);
        startServer(nextPort, attempts + 1);
      } else {
        console.error('Server failed to start:', err);
      }
    });
  } catch (err) {
    console.error('Server start error:', err);
  }
}

startServer(PORT);
