import crypto from "crypto";
import express from "express";
import { chain } from "../server.js";

export const walletRouter = express.Router();

// In-memory wallet store
const wallets = {};

// Get wallet list
walletRouter.get("/", (req, res) => {
    res.json({
        wallets: Object.keys(wallets),
        count: Object.keys(wallets).length,
        message: "Available wallets"
    });
});

// Get wallet balance
walletRouter.get("/balance/:address", (req, res) => {
    const { address } = req.params;
    let balance = 0;
    chain.forEach(block => {
        block.transactions.forEach(tx => {
            if (tx.to === address) balance += tx.amount;
            if (tx.from === address) balance -= tx.amount;
        });
    });
    res.json({ address, balance });
});

// Create new wallet
walletRouter.post("/create", (req, res) => {
    const address = crypto.randomBytes(20).toString("hex");
    wallets[address] = 1000; // Initial balance
    res.json({
        success: true,
        address,
        initialBalance: 1000,
        message: "Wallet created successfully"
    });
});

// Transfer funds
walletRouter.post("/transfer", (req, res) => {
    const { from, to, amount } = req.body;

    if (!from || !to || !amount || amount <= 0) {
        return res.status(400).json({
            success: false,
            error: "Invalid transfer parameters"
        });
    }

    if (!wallets[from]) {
        return res.status(404).json({
            success: false,
            error: "Sender wallet not found"
        });
    }

    if (wallets[from] < amount) {
        return res.status(400).json({
            success: false,
            error: "Insufficient balance"
        });
    }

    wallets[from] -= amount;
    wallets[to] = (wallets[to] || 0) + amount;

    res.json({
        success: true,
        from,
        to,
        amount,
        fromBalance: wallets[from],
        toBalance: wallets[to]
    });
});
