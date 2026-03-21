import bodyParser from "body-parser";
import cors from "cors";
import crypto from "crypto";
import dotenv from "dotenv";
import express from "express";
import rateLimit from "express-rate-limit";
import http from "http";
import https from "https";
import path from "path";
import { fileURLToPath, URL as NodeURL } from "url";

import { authRouter } from "./routes/auth.js";
import { blockchainRouter } from "./routes/blockchain.js";
import { marketRouter } from "./routes/market.js";
import { miningRouter } from "./routes/mining.js";
import { statsRouter } from "./routes/stats.js";
import { tradeRouter } from "./routes/trade.js";
import { userRouter } from "./routes/user.js";
import { walletRouter } from "./routes/wallet.js";

// Set up __dirname for ES6 modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config();
const app = express();
const PORT = process.env.PORT || 5000;
const BACKEND_HOST = process.env.BACKEND_HOST || "localhost";
const RPC_URL = process.env.RPC_URL || `http://${process.env.RPC_HOST || "daemon"}:8545`;
const NAME = process.env.NAME || "SpiralCoin";
const SYMBOL = process.env.SYMBOL || "SPRC";

app.use(cors());
app.use(bodyParser.json());

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
app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
    try {
        res.sendFile(path.join(__dirname, "public/index.html"));
    } catch (err) {
        res.status(200).json({ status: 'SpiralCoin API Running' });
    }
});

// Serve trading platform page from public to ensure availability in all deployments
app.get('/trading_platform.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'trading_platform.html'));
});

// Helpful aliases to reach the trading UI
app.get(['/trading', '/trade', '/start', '/app/trade'], (req, res) => {
    res.redirect(302, '/trading_platform.html');
});

// Convenient routes for auth and dashboard pages
app.get('/login', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'login.html'));
});
app.get('/register', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'register.html'));
});
app.get('/dashboard', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'dashboard.html'));
});

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'healthy', ts: new Date().toISOString() });
});

// Basic project info for exchanges and integrations
app.get('/api/info', async (req, res) => {
    try {
        // Derive current status for inclusion
        let chainId = "0x0";
        let blockNumber = chain.length;
        try {
            const statusUrl = `${req.protocol}://${req.get('host')}/api/status`;
            const s = await (await fetch(statusUrl)).json();
            chainId = s.chainId || chainId;
            blockNumber = (typeof s.blockNumber !== 'undefined') ? s.blockNumber : blockNumber;
        } catch {}
        const publicRpc = `${req.protocol}://${req.get('host')}/api/rpc`;
        res.json({
            name: NAME,
            symbol: SYMBOL,
            chainId,
            rpcUrl: publicRpc,
            endpoints: {
                health: '/health',
                status: '/api/status',
                rpcProxy: '/api/rpc',
                marketPrice: '/api/market/price',
                wallet: '/api/wallet'
            }
        });
    } catch (err) {
        res.status(200).json({ name: NAME, symbol: SYMBOL, rpcUrl: '/api/rpc', error: err.message });
    }
});

// Routes
app.use("/api/market", marketRouter);
app.use("/api/trade", tradeRouter);
app.use("/api/auth", authRouter);
app.use("/api/user", userRouter);
app.use("/api/blockchain", blockchainRouter);
app.use("/api/mining", miningRouter);
app.use("/api/stats", statsRouter);
app.use("/api/wallet", walletRouter);

// JSON-RPC proxy to SpiralCoin daemon (port 8545 by default)
async function rpcCall(method, params = []) {
    const urlObj = new NodeURL(RPC_URL);
    const payload = JSON.stringify({ jsonrpc: "2.0", id: Date.now(), method, params });
    const options = {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
            "Content-Length": Buffer.byteLength(payload)
        }
    };

    return new Promise((resolve, reject) => {
        const lib = urlObj.protocol === "https:" ? https : http;
        const rpcPath = (!urlObj.pathname || urlObj.pathname === "/") ? "/rpc" : urlObj.pathname;
        const req = lib.request(
            {
                hostname: urlObj.hostname,
                port: urlObj.port || (urlObj.protocol === "https:" ? 443 : 80),
                path: rpcPath,
                method: options.method,
                headers: options.headers
            },
            (res) => {
                let body = "";
                res.on("data", (chunk) => (body += chunk));
                res.on("end", () => {
                    try {
                        resolve(JSON.parse(body));
                    } catch (e) {
                        reject(e);
                    }
                });
            }
        );
        // Add a short timeout to avoid hanging when RPC is unavailable
        req.setTimeout(3000, () => {
            req.destroy(new Error("RPC request timed out"));
        });
        req.on("error", reject);
        req.write(payload);
        req.end();
    });
}

// Forward arbitrary RPC calls
app.post("/api/rpc", async (req, res) => {
    try {
        const { method, params } = req.body || {};
        if (!method) return res.status(400).json({ error: "Missing method" });
        const result = await rpcCall(method, params || []);
        res.json(result);
    } catch (err) {
        console.error("/api/rpc error:", err);
        res.status(500).json({ error: err.message });
    }
});

// Dump wallet info from daemon (addresses and balances)
app.get('/api/wallet/info', async (_req, res) => {
    try {
        const r = await rpcCall('getwalletinfo', []);
        res.json(r?.result || r || {});
    } catch (err) {
        res.status(200).json({ error: err.message });
    }
});

// On-chain wallet balance via daemon RPC
app.get('/api/wallet/balance/onchain/:address', async (req, res) => {
    try {
        const { address } = req.params;
        if (!address) return res.status(400).json({ error: 'Missing address' });
        const r = await rpcCall('getbalance', [address]);
        const balance = (typeof r?.result !== 'undefined') ? Number(r.result) : null;
        res.json({ address, balance, source: 'daemon' });
    } catch (err) {
        res.status(200).json({ address: req.params.address, error: err.message });
    }
});

// Verify supply balances remain secured in designated wallets
app.get('/api/wallet/verify-supply', async (req, res) => {
    try {
        const primary = process.env.PRIMARY_WALLET || '0x928072b3A3A42e7dFD577a91167DfAa08f0E653E';
        const vault = process.env.SUPPLY_VAULT || '0xSPRC1111111111111111111111111111SupplyVault';
        const expectedMin = Number(req.query.min || process.env.SUPPLY_MIN || 22000000000000);
        const listParam = (req.query.addresses || '').toString().trim();
        const addresses = listParam
            ? listParam.split(',').map(s => s.trim()).filter(Boolean)
            : [primary, vault];

        const results = await Promise.all(addresses.map(a => rpcCall('getbalance', [a]).catch(() => null)));
        const details = addresses.map((addr, i) => ({ address: addr, balance: (results[i] && typeof results[i].result !== 'undefined') ? Number(results[i].result) : 0 }));
        const total = details.reduce((acc, d) => acc + (Number.isFinite(d.balance) ? d.balance : 0), 0);
        const ok = total >= expectedMin;
        res.json({
            ok,
            expectedMin,
            total,
            addresses: details
        });
    } catch (err) {
        res.status(200).json({ ok: false, error: err.message });
    }
});

// Chain status using RPC
app.get("/api/status", async (_req, res) => {
    try {
        // Try Ethereum-style methods first; if unavailable, fall back to SpiralCoin RPCs
        let chainId = "0x0";
        let blockNumber = 0;
        let gasPriceWei = 0;
        let peerCount = 0;

        const hexToInt = (h) => (h ? parseInt(h, 16) : 0);

        try {
            const [chainIdResp, blockResp, gasResp, peerResp] = await Promise.all([
                rpcCall("eth_chainId"),
                rpcCall("eth_blockNumber"),
                rpcCall("eth_gasPrice"),
                rpcCall("net_peerCount").catch(() => ({ result: "0x0" }))
            ]);
            chainId = chainIdResp?.result || "0x0";
            blockNumber = hexToInt(blockResp?.result);
            gasPriceWei = hexToInt(gasResp?.result);
            peerCount = hexToInt(peerResp?.result);
        } catch (_) {
            // Fallbacks for non-EVM RPC
            const countResp = await rpcCall("getblockcount").catch(() => null);
            if (countResp && typeof countResp.result !== "undefined") {
                blockNumber = Number(countResp.result) || 0;
            } else {
                blockNumber = chain.length;
            }
            // peerCount fallback remains 0
        }

        res.json({ rpcUrl: '/api/rpc', chainId, blockNumber, gasPriceWei, peerCount });
    } catch (err) {
        console.error("/api/status error:", err);
        res.status(200).json({
            rpcUrl: '/api/rpc',
            error: err.message,
            chainLengthFallback: chain.length,
            pendingTxFallback: pendingTransactions.length
        });
    }
});

// Exchange-friendly aggregate info combining /api/info and /api/status
app.get('/api/exchange/info', async (req, res) => {
    try {
        const baseUrl = `${req.protocol}://${req.get('host')}`;
        const [infoResp, statusResp] = await Promise.all([
            (async () => {
                try { return await (await fetch(`${baseUrl}/api/info`)).json(); } catch { return {}; }
            })(),
            (async () => {
                try { return await (await fetch(`${baseUrl}/api/status`)).json(); } catch { return {}; }
            })()
        ]);
        const publicRpc = `${req.protocol}://${req.get('host')}/api/rpc`;
        res.json({
            name: infoResp.name || NAME,
            symbol: infoResp.symbol || SYMBOL,
            rpcUrl: publicRpc,
            chainId: statusResp.chainId || '0x0',
            blockNumber: statusResp.blockNumber ?? statusResp.chainLengthFallback ?? 0,
            peerCount: statusResp.peerCount ?? 0,
            endpoints: infoResp.endpoints || {
                health: '/health', status: '/api/status', rpcProxy: '/api/rpc', marketPrice: '/api/market/price', wallet: '/api/wallet'
            },
            error: statusResp.error
        });
    } catch (err) {
        res.status(200).json({ name: NAME, symbol: SYMBOL, rpcUrl: '/api/rpc', error: err.message });
    }
});

// Exchange info pages
app.get(['/exchange', '/listing'], (req, res) => {
    res.sendFile(path.join(__dirname, 'public/exchange.html'));
});

// Global error handler
app.use((err, req, res, next) => {
    console.error("Unhandled error:", err);
    res.status(500).json({ success: false, error: err.message });
});

// Start server
app.listen(PORT, () => console.log(`✅ SpiralCoin backend running on port ${PORT}`));
