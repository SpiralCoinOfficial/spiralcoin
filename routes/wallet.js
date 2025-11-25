import express from "express";
import { chain } from "../server.js";

export const walletRouter = express.Router();

walletRouter.get("/balance/:address", (req, res) => {
    const { address } = req.params;
    let balance = 0;
    chain.forEach(block => {
        block.transactions.forEach(tx => {
            if (tx.to === address) balance += tx.amount;
            if (tx.from === address) balance -= tx.amount;
        });
    });
    res.json({ balance });
});
