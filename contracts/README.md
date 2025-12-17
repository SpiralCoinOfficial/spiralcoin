# SpiralCoin Contracts (ERC20/BEP20)

This subproject provides a minimal Hardhat setup to deploy the SpiralCoin token to Ethereum (ERC20) and BSC (BEP20). The same contract works on both chains.

## Prerequisites
- Node.js 18+
- An RPC URL per network (Alchemy/Infura for Ethereum; public RPC for BSC)
- A funded deployer private key (without 0x) for gas fees

## Setup
```bash
cd contracts
npm install
cp .env.example .env
# Edit .env with PRIVATE_KEY, ETHEREUM_RPC_URL/BSC_RPC_URL, and token parameters
```

## Compile
```bash
npm run compile
```

## Deploy
- Ethereum mainnet/testnet:
```bash
npm run deploy:ethereum
```
- BSC mainnet/testnet (set BSC_RPC_URL accordingly):
```bash
npm run deploy:bsc
```

Deployment writes JSON artifacts to `contracts/build/deployment_<network>.json` with address and parameters for documentation and exchange pack updates.

## Token Parameters
Set in `.env`:
- `TOKEN_NAME` (default: SpiralCoin)
- `TOKEN_SYMBOL` (default: SPRC)
- `TOKEN_DECIMALS` (default: 18)
- `TOKEN_INITIAL_SUPPLY` (default: 1,000,000,000)
- `TOKEN_OWNER` (optional; default deployer)

## Notes
- For production, confirm final name/symbol/supply with your compliance and tokenomics plan before mainnet.
- Verify contracts on Etherscan/BscScan after deployment.
- Add resulting addresses to `exchange_manifest.json` and docs.
