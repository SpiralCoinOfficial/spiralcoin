import express from "express";
import { chain } from "../server.js";

export const blockchainRouter = express.Router();

blockchainRouter.get("/", (req, res) => {
    res.json({ chain });
});
