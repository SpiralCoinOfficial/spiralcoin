import express from "express";
import * as crypto from "node:crypto";
import { chain, pendingTransactions } from "../server.js";

export const miningRouter = express.Router();

miningRouter.post("/", (req, res) => {
    const previousBlock = chain[chain.length - 1];
    const block = {
        index: chain.length,
        timestamp: Date.now(),
        transactions: [...pendingTransactions],
        nonce: Math.floor(Math.random() * 1000000),
        previousHash: previousBlock.hash
    };
    block.hash = crypto.createHash("sha256").update(JSON.stringify(block)).digest("hex");
    chain.push(block);
    pendingTransactions.length = 0;
    res.json({ block });
});

miningRouter.post("/transaction", (req, res) => {
    const { from, to, amount } = req.body;
    if (!from || !to || !amount || amount <= 0) return res.status(400).json({ error: "Invalid transaction" });
    pendingTransactions.push({ from, to, amount });
    res.json({ pendingTransactions });
});
