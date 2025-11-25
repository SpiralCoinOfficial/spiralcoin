import express from "express";
import { chain, pendingTransactions } from "../server.js";

export const statsRouter = express.Router();

statsRouter.get("/", (req, res) => {
    let totalCoins = 0;
    chain.forEach(block => {
        block.transactions.forEach(tx => totalCoins += tx.amount);
    });
    res.json({
        blocks: chain.length,
        pendingTransactions: pendingTransactions.length,
        totalCoins
    });
});
