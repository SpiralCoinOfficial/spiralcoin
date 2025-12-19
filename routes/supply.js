import express from "express";

export const supplyRouter = express.Router();

// Read supply configuration from environment with sensible defaults
const founderWallet = process.env.FOUNDER_WALLET || "0x928072b3A3A42e7dFD577a91167DfAa08f0E653E";
const supplyWallet = process.env.SUPPLY_WALLET || "0xSPRC1111111111111111111111111111SupplyVault";
const founderBalance = Number(process.env.FOUNDER_BALANCE ?? "30562600"); // 30,562,600 SPRC
const supplyBalance = Number(process.env.SUPPLY_BALANCE ?? "20000000000000"); // 20,000,000,000,000 SPRC
const totalSupplyEnv = process.env.TOTAL_SUPPLY;
const totalSupply = Number(totalSupplyEnv ?? (founderBalance + supplyBalance));

function toResponse() {
  return {
    ticker: "SPRC",
    founderWallet,
    supplyWallet,
    founderBalance,
    supplyBalance,
    totalSupply
  };
}

// GET /api/supply
supplyRouter.get("/", (_req, res) => {
  res.json(toResponse());
});

// GET /api/supply/founder
supplyRouter.get("/founder", (_req, res) => {
  res.json({ address: founderWallet, balance: founderBalance, ticker: "SPRC" });
});

// GET /api/supply/vault
supplyRouter.get("/vault", (_req, res) => {
  res.json({ address: supplyWallet, balance: supplyBalance, ticker: "SPRC" });
});

// GET /api/supply/total
supplyRouter.get("/total", (_req, res) => {
  res.json({ totalSupply, ticker: "SPRC" });
});
