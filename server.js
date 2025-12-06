import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import dotenv from "dotenv";
import crypto from "crypto";
import path from "path";
import { fileURLToPath } from "url";
import rateLimit from "express-rate-limit";

import { marketRouter } from "./routes/market.js";
import { blockchainRouter } from "./routes/blockchain.js";
import { miningRouter } from "./routes/mining.js";
import { statsRouter } from "./routes/stats.js";
import { walletRouter } from "./routes/wallet.js";

dotenv.config();
const app = express();
const PORT = process.env.PORT || 5000;

app.use(cors());
app.use(bodyParser.json());

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

// Rate limiter: max 100 requests per 15 minutes per IP
const rateLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100, // limit each IP to 100 requests per windowMs
});

app.use(express.static(path.join(__dirname, "public")));
app.get("/", rateLimiter, (req, res) => {
    res.sendFile(path.join(__dirname, "public/index.html"));
});

// Routes
app.use("/api/market", marketRouter);
app.use("/api/blockchain", blockchainRouter);
app.use("/api/mining", miningRouter);
app.use("/api/stats", statsRouter);
app.use("/api/wallet", walletRouter);

// Global error handler
app.use((err, req, res, next) => {
    console.error("Unhandled error:", err);
    res.status(500).json({ success: false, error: err.message });
});

// Start server
app.listen(PORT, () => console.log(`✅ SpiralCoin backend running on port ${PORT}`));
