import crypto from "crypto";
import express from "express";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

export const tradeRouter = express.Router();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.join(__dirname, "..");
const DATA_DIR = path.join(ROOT, "data");
const ORDERS_FILE = path.join(DATA_DIR, "trade_orders.json");

function ensureStore() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(ORDERS_FILE)) fs.writeFileSync(ORDERS_FILE, JSON.stringify({ orders: [] }, null, 2));
}
function readOrders() {
  try { return JSON.parse(fs.readFileSync(ORDERS_FILE, "utf8")); } catch { return { orders: [] }; }
}
function writeOrders(obj) {
  const tmp = ORDERS_FILE + ".tmp";
  fs.writeFileSync(tmp, JSON.stringify(obj, null, 2));
  fs.renameSync(tmp, ORDERS_FILE);
}

ensureStore();

// Supported markets (expandable). For now, provide a safe default list.
const SUPPORTED = [
  { symbol: "SPRC/USD", base: "SPRC", quote: "USD" },
  { symbol: "SPRC/BTC", base: "SPRC", quote: "BTC" },
  { symbol: "BTC/USD", base: "BTC", quote: "USD" },
  { symbol: "ETH/USD", base: "ETH", quote: "USD" }
];

tradeRouter.get("/markets", (_req, res) => {
  res.json({ markets: SUPPORTED });
});

// Paper trading engine (no external exchange calls unless explicitly configured)
tradeRouter.post("/order", (req, res) => {
  try {
    const { symbol, side, quantity, price, type } = req.body || {};
    if (!symbol || !side || !quantity) return res.status(400).json({ error: "Missing symbol, side, or quantity" });
    const mkt = SUPPORTED.find(m => m.symbol === symbol);
    if (!mkt) return res.status(400).json({ error: "Unsupported market" });
    const order = {
      id: "ord_" + crypto.randomUUID().replace(/-/g, ""),
      ts: Date.now(), symbol, side: String(side).toUpperCase(),
      quantity: Number(quantity), type: type || (price ? "LIMIT" : "MARKET"), price: price ? Number(price) : null,
      status: "FILLED"
    };
    const store = readOrders();
    store.orders.unshift(order);
    if (store.orders.length > 500) store.orders.length = 500;
    writeOrders(store);
    res.json({ ok: true, order });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

tradeRouter.get("/orders", (_req, res) => {
  const store = readOrders();
  res.json(store);
});

// Placeholder for connecting to real exchanges securely – requires API keys and compliance.
tradeRouter.get("/exchanges/config", (_req, res) => {
  const cfg = {
    binance: Boolean(process.env.BINANCE_API_KEY && process.env.BINANCE_API_SECRET),
    coinbase: Boolean(process.env.COINBASE_API_KEY && process.env.COINBASE_API_SECRET)
  };
  res.json({ configured: cfg });
});
