# Smart Contract Deployment Instructions

This directory contains everything needed to deploy the SpiralCoin ERC-20 token contract.

## Quick Start (Automated)

Run the interactive deployment guide:
```bash
bash scripts/deploy-contract-interactive.sh
```

This will:
1. Prompt you to select a blockchain network
2. Verify your private key setup
3. Deploy the contract
4. Update the root `.env` file with the contract address
5. Run the exchange readiness gate check
6. Verify that `READY_FOR_EXCHANGE_LISTING=YES`

## Manual Deployment

### Prerequisites
1. **Private Key**: Set in `contracts/.env`
   ```bash
   echo "PRIVATE_KEY=0x..." > contracts/.env
   ```

2. **Network Configuration**: Edit `contracts/hardhat.config.js` to add custom networks if needed

3. **Token Configuration** (optional): Edit `contracts/.env`
   ```bash
   TOKEN_NAME=SpiralCoin
   TOKEN_SYMBOL=SPRC
   TOKEN_DECIMALS=18
   TOKEN_INITIAL_SUPPLY=1000000000
   TOKEN_OWNER=0x...  # If different from deployer
   ```

### Deploy to Ethereum Sepolia (testnet)
```bash
cd contracts
npx hardhat run scripts/deploy.js --network sepolia
```

### Deploy to Ethereum Mainnet (production)
```bash
cd contracts
npx hardhat run scripts/deploy.js --network ethereum
```

### Deploy to Polygon Mumbai (testnet)
```bash
cd contracts
npx hardhat run scripts/deploy.js --network mumbai
```

### Deploy to Polygon Mainnet (production)
```bash
cd contracts
npx hardhat run scripts/deploy.js --network polygon
```

### Deploy to BSC Testnet
```bash
cd contracts
npx hardhat run scripts/deploy.js --network bsc-testnet
```

### Deploy to BSC Mainnet (production)
```bash
cd contracts
npx hardhat run scripts/deploy.js --network bsc
```

## After Deployment

1. **Copy contract address** from deployment output

2. **Update root .env file**:
   ```bash
   # In /workspaces/spiralcoin/.env
   SUPPLY_VAULT=0x<contract-address-here>
   ```

3. **Verify exchange readiness**:
   ```bash
   bash scripts/exchange-readiness-gate.sh
   # Should output: READY_FOR_EXCHANGE_LISTING=YES
   ```

4. **Commit deployment**:
   ```bash
   git add .env
   git commit -m "feat: deploy SpiralCoin contract to <network>"
   git push
   ```

5. **Generate exchange pack**:
   ```bash
   npm run build:exchange
   ```

6. **Submit to exchanges**

## Supported Networks

| Network | Network ID | RPC Endpoint | Type |
|---------|-----------|--------------|------|
| Ethereum Mainnet | ethereum | https://eth.blockscout.com | Production |
| Ethereum Sepolia | sepolia | https://sepolia.etherscan.io | Testnet |
| Polygon Mainnet | polygon | https://polygonscan.com | Production |
| Polygon Mumbai | mumbai | https://mumbai.polygonscan.com | Testnet |
| BSC Mainnet | bsc | https://bscscan.com | Production |
| BSC Testnet | bsc-testnet | https://testnet.bscscan.com | Testnet |

## Troubleshooting

### "Error: No funds available"
- Fund the deployer wallet with native token (ETH, MATIC, BNB)
- Use faucet for testnet: https://faucets.chain.link/

### "Error: Private key invalid"
- Ensure `PRIVATE_KEY` is set in `contracts/.env`
- Check format: `0x` followed by 64 hex characters
- Don't commit private keys - use environment variables

### "Error: Network not configured"
- Check `contracts/hardhat.config.js` for network definition
- Ensure RPC URL is correct in configuration
- Test RPC connectivity: `curl <RPC_URL>`

### "Error: Contract deployment failed"
- Check gas price and balance
- Verify contract bytecode compiles: `npx hardhat compile`
- Check network-specific requirements (e.g., token size limits)

## Contract Details

**Contract**: ERC-20 Token Contract (SPRC)
**Location**: `contracts/contracts/SPRC.sol`
**Deployer Script**: `contracts/scripts/deploy.js`
**Configuration**: `contracts/.env`, `contracts/hardhat.config.js`

## Security Notes

- ⚠️ **NEVER commit private keys to version control**
- ⚠️ **Use environment variables or `.env` files (git-ignored)**
- ⚠️ **For production, use hardware wallet or key management service**
- ⚠️ **Test on testnet first before mainnet deployment**
- ✅ Verify contract on block explorer after deployment
- ✅ Keep deployment addresses in documentation

---

**For automated deployment**: `bash scripts/deploy-contract-interactive.sh`
**For manual deployment**: Follow steps above
**Support**: See FINAL_COMPLETION_REPORT.md for full context
