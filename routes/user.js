import express from "express";
import http from "http";
import https from "https";
import { URL as NodeURL } from "url";
import { authMiddleware, readStores, writeUserWallets } from "./auth.js";

export const userRouter = express.Router();

function rpcCall(rpcUrl, method, params = []) {
  const urlObj = new NodeURL(rpcUrl);
  const payload = JSON.stringify({ jsonrpc: "2.0", id: Date.now(), method, params });
  const options = { method: "POST", headers: { "Content-Type": "application/json", "Content-Length": Buffer.byteLength(payload) } };
  return new Promise((resolve, reject) => {
    const lib = urlObj.protocol === "https:" ? https : http;
    const rpcPath = (!urlObj.pathname || urlObj.pathname === "/") ? "/rpc" : urlObj.pathname;
    const req = lib.request({ hostname: urlObj.hostname, port: urlObj.port || (urlObj.protocol === "https:" ? 443 : 80), path: rpcPath, method: options.method, headers: options.headers }, (res) => {
      let body = ""; res.on("data", (c) => body += c); res.on("end", () => { try { resolve(JSON.parse(body)); } catch (e) { reject(e); } });
    });
    req.setTimeout(3000, () => req.destroy(new Error("RPC request timed out")));
    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}

userRouter.use(authMiddleware);

userRouter.get("/me", (req, res) => {
  const { users } = readStores();
  const u = users.users.find(x => x.id === req.user.id);
  if (!u) return res.status(404).json({ error: "User not found" });
  res.json({ id: u.id, username: u.username, settings: u.settings || {} });
});

userRouter.get("/wallet/my", async (req, res) => {
  try {
    const rpcUrl = process.env.RPC_URL || "http://daemon:8545";
    const { userWallets } = readStores();
    const addrs = userWallets.wallets[req.user.id] || [];
    const balances = [];
    for (const a of addrs) {
      const r = await rpcCall(rpcUrl, 'getbalance', [a]).catch(() => null);
      const bal = (r && typeof r.result !== 'undefined') ? Number(r.result) : 0;
      balances.push({ address: a, balance: bal });
    }
    res.json({ addresses: balances });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

userRouter.post("/wallet/new", async (req, res) => {
  try {
    const rpcUrl = process.env.RPC_URL || "http://daemon:8545";
    // Try SpiralCoin RPC first
    let addr = null;
    const r1 = await rpcCall(rpcUrl, 'getnewaddress', []).catch(() => null);
    if (r1 && typeof r1.result !== 'undefined' && r1.result) {
      addr = r1.result;
    }
    // Fallback to EVM-compatible personal_newAccount
    if (!addr) {
      const r2 = await rpcCall(rpcUrl, 'personal_newAccount', ["SpiralAuto"]).catch(() => null);
      if (r2 && typeof r2.result !== 'undefined' && r2.result) {
        addr = r2.result;
      }
    }
    if (!addr) return res.status(500).json({ error: "Failed to create address" });
    const stores = readStores();
    if (!stores.userWallets.wallets[req.user.id]) stores.userWallets.wallets[req.user.id] = [];
    if (!stores.userWallets.wallets[req.user.id].includes(addr)) stores.userWallets.wallets[req.user.id].push(addr);
    writeUserWallets(stores.userWallets);
    res.json({ address: addr });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
