import dotenv from "dotenv";
import { defineConfig } from "hardhat/config";

dotenv.config();

export default defineConfig({
  solidity: "0.8.24",
  networks: {
    arbitrumOne: {
      type: "http",
      url: process.env.ARBITRUM_RPC || "https://arb1.arbitrum.io/rpc",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  }
});
