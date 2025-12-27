import express from "express";
import { promises as fs } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const marketRouter = express.Router();

// Ensure fetch exists in environments without global fetch
const fetch = globalThis.fetch ?? (await import("undici")).fetch;

let currentPrice = 0.05;

// Simple in-memory OHLC candles for charting
// Each candle: { time: number (unix in seconds), open: number, high: number, low: number, close: number }
let candles = [];

// Persistence paths for SPRC candles
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dataDir = path.join(__dirname, "..", "data");
const sprcCandlesPath = path.join(dataDir, "candles_sprc.json");

async function loadSprcCandles() {
    try {
        const raw = await fs.readFile(sprcCandlesPath, "utf8");
        const parsed = JSON.parse(raw);
        if (Array.isArray(parsed) && parsed.length) {
            candles = parsed;
            const last = candles[candles.length - 1];
            if (last && typeof last.close === "number") currentPrice = last.close;
            return true;
        }
    } catch {}
    return false;
}

async function saveSprcCandles() {
    try {
        await fs.mkdir(dataDir, { recursive: true });
        await fs.writeFile(sprcCandlesPath, JSON.stringify(candles), "utf8");
    } catch {
        // best-effort; ignore persistence failures
    }
}
function initCandles() {
    const now = Math.floor(Date.now() / 1000);
    const base = currentPrice;
    const seedCount = 180; // 3 hours of 1m candles
    let prevClose = base;
    for (let i = seedCount; i > 0; i--) {
        const t = now - i * 60;
        const drift = Math.sin(i / 10) * 0.002 + (Math.random() - 0.5) * 0.002;
        const open = prevClose;
        const close = Math.max(0.0001, open * (1 + drift));
        const high = Math.max(open, close) * (1 + Math.random() * 0.001);
        const low = Math.min(open, close) * (1 - Math.random() * 0.001);
        candles.push({
            time: t,
            open: Number(open.toFixed(6)),
            high: Number(high.toFixed(6)),
            low: Number(low.toFixed(6)),
            close: Number(close.toFixed(6))
        });
        prevClose = close;
    }
}

// Initialize from disk if available; otherwise seed
const _init = await loadSprcCandles();
if (!_init || candles.length === 0) {
    initCandles();
    await saveSprcCandles();
}

marketRouter.get("/price", (_req, res) => {
    res.json({ price: currentPrice });
});

marketRouter.post("/update", (req, res) => {
    const { price } = req.body || {};
    if (typeof price !== "number" || !(price > 0)) {
        return res.status(400).json({ error: "Invalid price" });
    }
    currentPrice = price;
    // Append a new candle using the updated price
    const now = Math.floor(Date.now() / 1000);
    const last = candles[candles.length - 1] || { close: currentPrice };
    const open = last.close;
    const close = currentPrice;
    const high = Math.max(open, close) * (1 + Math.random() * 0.001);
    const low = Math.min(open, close) * (1 - Math.random() * 0.001);
    candles.push({
        time: now,
        open: Number(open.toFixed(6)),
        high: Number(high.toFixed(6)),
        low: Number(low.toFixed(6)),
        close: Number(close.toFixed(6))
    });
    if (candles.length > 1440) candles.shift(); // cap at ~1 day of 1m candles
    // persist update
    saveSprcCandles();
    res.json({ price: currentPrice });
});

const CG_BASE = "https://api.coingecko.com/api/v3";
async function fetchJson(url) {
    const res = await fetch(url, { cache: "no-store" });
    const ct = res.headers.get("content-type") || "";
    if (!ct.includes("application/json")) {
        const txt = await res.text();
        try {
            return JSON.parse(txt);
        } catch {
            return null;
        }
    }
    return await res.json();
}

async function resolveCoingeckoId(asset) {
    if (!asset) return null;
    const a = asset.toString().trim();
    // If looks like a CG id (has hyphen), try direct
    if (a.includes("-")) return a.toLowerCase();
    // Search by symbol/name
    try {
        const data = await fetchJson(`${CG_BASE}/search?query=${encodeURIComponent(a)}`);
        const coins = Array.isArray(data?.coins) ? data.coins : [];
        const upper = a.toUpperCase();
        const exact = coins.filter((c) => c.symbol?.toUpperCase() === upper);
        const pick = (exact.length ? exact : coins).sort(
            (x, y) => (x.market_cap_rank || 1e9) - (y.market_cap_rank || 1e9)
        )[0];
        return pick?.id || null;
    } catch {
        return null;
    }
}

// Candles endpoint for interactive chart
// Query params: asset (symbol or coingecko id), vs (currency), interval (1m/5m/1h/1d)
marketRouter.get("/candles", async (req, res) => {
    try {
        let asset = (req.query.asset || req.query.pair || "SPRC").toString();
        // Map known local identifiers to SPRC
        if (asset.toLowerCase() === 'spiralcoin' || asset.toUpperCase() === 'SPC') {
            asset = 'SPRC';
        }
        const vs = (req.query.vs || "USD").toString().toLowerCase();
        const interval = (req.query.interval || "1h").toString();

        // If asking for SPRC, return local in-memory candles
        if (asset.toUpperCase() === "SPRC" || asset.toUpperCase() === "SPC") {
            return res.json({ asset: "SPRC", vs, interval, candles });
        }

        if (asset.toLowerCase().startsWith("0x")) {
            return res.status(400).json({ error: "Token addresses are not supported in this demo." });
        }

        // Resolve symbol or id to a CoinGecko id (broad asset support)
        const cgId = await resolveCoingeckoId(asset);
        if (!cgId) {
            return res
                .status(400)
                .json({ error: "Asset not found. Try using search endpoint to find valid assets." });
        }

        // Map interval to days for CoinGecko OHLC
        const daysMap = { "1m": 1, "5m": 1, "1h": 1, "1d": 7, "7d": 30 };
        const days = daysMap[interval] || 1;
        const url = `${CG_BASE}/coins/${cgId}/ohlc?vs_currency=${encodeURIComponent(vs)}&days=${days}`;
        const ohlc = await fetchJson(url);
        if (!Array.isArray(ohlc)) {
            return res.status(502).json({ error: "Failed to retrieve OHLC data" });
        }
        // CoinGecko OHLC format: [time(ms), open, high, low, close]
        const out = ohlc.map((row) => ({
            time: Math.floor(row[0] / 1000),
            open: row[1],
            high: row[2],
            low: row[3],
            close: row[4]
        }));
        return res.json({ asset: asset.toUpperCase(), vs, interval, candles: out });
    } catch (err) {
        return res.status(502).json({ error: "Failed to load external candles", details: err?.message || String(err) });
    }
});

// Supported pairs listing (demo)
marketRouter.get("/pairs", (_req, res) => {
    res.json({
        networks: [
            { id: "SPRC", name: "Spiral Mainnet" },
            { id: "ETH", name: "Ethereum" },
            { id: "BSC", name: "Binance Smart Chain" },
            { id: "SOL", name: "Solana" }
        ],
        assets: [
            { id: "spiralcoin", symbol: "SPRC", name: "SpiralCoin", network: "SPRC" },
            { id: "bitcoin", symbol: "BTC", name: "Bitcoin", network: "ETH" },
            { id: "ethereum", symbol: "ETH", name: "Ethereum", network: "ETH" },
            { id: "tether", symbol: "USDT", name: "Tether", network: "ETH" },
            { id: "binancecoin", symbol: "BNB", name: "BNB", network: "BSC" },
            { id: "solana", symbol: "SOL", name: "Solana", network: "SOL" }
        ]
    });
});

// Asset search (broad market coverage)
marketRouter.get("/search", async (req, res) => {
    const q = (req.query.query || req.query.q || "").toString().trim();
    if (!q) return res.json({ coins: [] });
    try {
        const data = await fetchJson(`${CG_BASE}/search?query=${encodeURIComponent(q)}`);
        const coins = Array.isArray(data?.coins)
            ? data.coins.map((c) => ({ id: c.id, symbol: c.symbol, name: c.name, market_cap_rank: c.market_cap_rank }))
            : [];
        res.json({ coins });
    } catch (e) {
        res.status(502).json({ error: "Search failed", details: e?.message || String(e) });
    }
});

// --- Server-Sent Events (SSE) for live candles and quotes ---
function sseHeaders(res) {
    res.setHeader("Content-Type", "text/event-stream");
    res.setHeader("Cache-Control", "no-cache");
    res.setHeader("Connection", "keep-alive");
    // Hint to proxies like Nginx to avoid buffering
    res.setHeader("X-Accel-Buffering", "no");
}

function sseWrite(res, obj) {
    try { res.write(`data: ${JSON.stringify(obj)}\n\n`); } catch {}
}

marketRouter.get('/stream/candles', async (req, res) => {
    sseHeaders(res);
    const asset = (req.query.asset || req.query.pair || 'SPRC').toString();
    const vs = (req.query.vs || 'USD').toString().toLowerCase();
    const interval = (req.query.interval || '1h').toString();
    let timer = null;

    async function pushLastCandle() {
        try {
            if (asset.toUpperCase() === 'SPRC' || asset.toUpperCase() === 'SPC') {
                // Simulate minor drift for local candles
                const now = Math.floor(Date.now() / 1000);
                const last = candles[candles.length - 1];
                const open = last ? last.close : currentPrice;
                const drift = (Math.random() - 0.5) * 0.001; // ~0.1%
                const close = Math.max(0.0001, open * (1 + drift));
                const high = Math.max(open, close) * (1 + Math.random() * 0.0005);
                const low = Math.min(open, close) * (1 - Math.random() * 0.0005);
                const bar = { time: now, open: Number(open.toFixed(6)), high: Number(high.toFixed(6)), low: Number(low.toFixed(6)), close: Number(close.toFixed(6)) };
                candles.push(bar);
                if (candles.length > 1440) candles.shift();
                currentPrice = bar.close;
                sseWrite(res, { asset: 'SPRC', vs, interval, candle: bar });
            } else {
                const cgId = await resolveCoingeckoId(asset);
                if (!cgId) return sseWrite(res, { error: 'asset_not_found' });
                const daysMap = { '1m': 1, '5m': 1, '1h': 1, '1d': 7, '7d': 30 };
                const days = daysMap[interval] || 1;
                const url = `${CG_BASE}/coins/${cgId}/ohlc?vs_currency=${encodeURIComponent(vs)}&days=${days}`;
                const ohlc = await fetchJson(url);
                if (!Array.isArray(ohlc) || ohlc.length === 0) return;
                const row = ohlc[ohlc.length - 1];
                const bar = { time: Math.floor(row[0] / 1000), open: row[1], high: row[2], low: row[3], close: row[4] };
                sseWrite(res, { asset: asset.toUpperCase(), vs, interval, candle: bar });
            }
        } catch (e) {
            sseWrite(res, { error: 'sse_candles_error', details: e?.message || String(e) });
        }
    }

    // Initial push, then periodic updates
    await pushLastCandle();
    timer = setInterval(pushLastCandle, 15000);

    req.on('close', () => { try { if (timer) clearInterval(timer); } catch {} });
});

marketRouter.get('/stream/quotes', async (req, res) => {
    sseHeaders(res);
    const selfPort = req.socket?.localPort || 5000;
    const sprcUrl = `http://127.0.0.1:${selfPort}/api/market/price`;

    async function aggregateQuotes() {
        const coingeckoUrl = `${CG_BASE}/simple/price?ids=bitcoin,ethereum,tether&vs_currencies=usd&include_24hr_change=true`;
        const [cgResp, sprcResp] = await Promise.all([
            fetch(coingeckoUrl, { cache: 'no-store' }).catch(() => null),
            fetch(sprcUrl, { cache: 'no-store' }).catch(() => null)
        ]);
        const cgJson = cgResp ? await cgResp.json().catch(() => ({})) : {};
        const sprcJson = sprcResp ? await sprcResp.json().catch(() => ({})) : {};
        return {
            SPRC: { usd: typeof sprcJson.price === 'number' ? sprcJson.price : null, usd_24h_change: null },
            BTC: { usd: cgJson?.bitcoin?.usd ?? null, usd_24h_change: cgJson?.bitcoin?.usd_24h_change ?? null },
            ETH: { usd: cgJson?.ethereum?.usd ?? null, usd_24h_change: cgJson?.ethereum?.usd_24h_change ?? null },
            USDT: { usd: cgJson?.tether?.usd ?? null, usd_24h_change: cgJson?.tether?.usd_24h_change ?? null },
            ts: new Date().toISOString()
        };
    }

    let timer = null;
    try {
        const initial = await aggregateQuotes();
        sseWrite(res, initial);
        timer = setInterval(async () => {
            try { sseWrite(res, await aggregateQuotes()); } catch {}
        }, 15000);
    } catch (e) {
        sseWrite(res, { error: 'sse_quotes_error', details: e?.message || String(e) });
    }

    req.on('close', () => { try { if (timer) clearInterval(timer); } catch {} });
});

// Simple quotes JSON endpoint (non-streaming)
marketRouter.get('/quotes', async (req, res) => {
    try {
        const selfPort = req.socket?.localPort || 5000;
        const sprcUrl = `http://127.0.0.1:${selfPort}/api/market/price`;
        const coingeckoUrl = `${CG_BASE}/simple/price?ids=bitcoin,ethereum,tether&vs_currencies=usd&include_24hr_change=true`;
        const [cgResp, sprcResp] = await Promise.all([
            fetch(coingeckoUrl, { cache: 'no-store' }).catch(() => null),
            fetch(sprcUrl, { cache: 'no-store' }).catch(() => null)
        ]);
        const cgJson = cgResp ? await cgResp.json().catch(() => ({})) : {};
        const sprcJson = sprcResp ? await sprcResp.json().catch(() => ({})) : {};
        const data = {
            SPRC: { usd: typeof sprcJson.price === 'number' ? sprcJson.price : null, usd_24h_change: null },
            BTC: { usd: cgJson?.bitcoin?.usd ?? null, usd_24h_change: cgJson?.bitcoin?.usd_24h_change ?? null },
            ETH: { usd: cgJson?.ethereum?.usd ?? null, usd_24h_change: cgJson?.ethereum?.usd_24h_change ?? null },
            USDT: { usd: cgJson?.tether?.usd ?? null, usd_24h_change: cgJson?.tether?.usd_24h_change ?? null },
            ts: new Date().toISOString()
        };
        res.json(data);
    } catch (e) {
        res.status(502).json({ error: 'quotes_failed', details: e?.message || String(e) });
    }
});
