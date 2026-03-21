#!/bin/bash
# deploy-contract-interactive.sh
# Interactive guide for smart contract deployment

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║    SpiralCoin Smart Contract Deployment Interactive Guide    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Network selection
echo "Step 1: Select target blockchain network"
echo "  1. Ethereum Mainnet (production)"
echo "  2. Ethereum Sepolia (testnet)"
echo "  3. Polygon Mainnet"
echo "  4. Polygon Mumbai (testnet)"
echo "  5. Binance Smart Chain (mainnet)"
echo "  6. BSC Testnet"
echo ""
read -p "Enter your choice (1-6): " network_choice

case $network_choice in
  1) NETWORK="ethereum"; NETWORK_NAME="Ethereum Mainnet" ;;
  2) NETWORK="sepolia"; NETWORK_NAME="Ethereum Sepolia" ;;
  3) NETWORK="polygon"; NETWORK_NAME="Polygon Mainnet" ;;
  4) NETWORK="mumbai"; NETWORK_NAME="Polygon Mumbai" ;;
  5) NETWORK="bsc"; NETWORK_NAME="Binance Smart Chain" ;;
  6) NETWORK="bsc-testnet"; NETWORK_NAME="BSC Testnet" ;;
  *) echo "Invalid choice"; exit 1 ;;
esac

echo "✓ Selected: $NETWORK_NAME"
echo ""

# Step 2: Private key
echo "Step 2: Private Key (for contract deployment)"
echo "⚠️  WARNING: Never commit private keys to git"
echo "    Use environment variable or .env file instead"
echo ""
read -sp "Enter PRIVATE_KEY (or press Enter to use .env): " PRIVATE_KEY
echo ""

if [ -z "$PRIVATE_KEY" ]; then
  if [ -f "contracts/.env" ]; then
    echo "✓ Using PRIVATE_KEY from contracts/.env"
    source contracts/.env
  else
    echo "❌ Error: PRIVATE_KEY not set and contracts/.env not found"
    exit 1
  fi
fi

# Step 3: Verify configuration
echo ""
echo "Step 3: Verify Configuration"
echo "──────────────────────────────────────────"
if [ -f "contracts/.env" ]; then
  source contracts/.env
  echo "Token Name:        ${TOKEN_NAME:-SpiralCoin}"
  echo "Token Symbol:      ${TOKEN_SYMBOL:-SPRC}"
  echo "Decimals:          ${TOKEN_DECIMALS:-18}"
  echo "Initial Supply:    ${TOKEN_INITIAL_SUPPLY:-1000000000}"
  echo "Owner Address:     ${TOKEN_OWNER:-(deployer address)}"
else
  echo "⚠️  No contracts/.env found - using defaults"
  echo "Token Name:        SpiralCoin"
  echo "Token Symbol:      SPRC"
  echo "Decimals:          18"
  echo "Initial Supply:    1000000000"
  echo "Owner Address:     (deployer address)"
fi
echo ""
read -p "Continue with deployment? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Deployment cancelled"
  exit 0
fi

# Step 4: Deploy
echo ""
echo "Step 4: Deploying contract to $NETWORK_NAME..."
echo "────────────────────────────────────────────────"

cd contracts

# Set network environment variable
export HARDHAT_NETWORK="$NETWORK"

# Deploy
npx hardhat run scripts/deploy.js --network "$NETWORK"

echo ""
echo "Step 5: Contract Deployed Successfully ✓"
echo ""

# Step 6: Extract address and update .env
if [ -f "../build/deployment_${NETWORK}.json" ]; then
  CONTRACT_ADDRESS=$(jq -r '.address' "../build/deployment_${NETWORK}.json")
  echo "Deployed at: $CONTRACT_ADDRESS"
  echo ""
  echo "Step 6: Update Root .env File"
  echo "──────────────────────────────"
  echo "Adding contract address to ../.env"

  cd ..

  # Update or add SUPPLY_VAULT in .env
  if grep -q "^SUPPLY_VAULT=" .env; then
    sed -i.bak "s/^SUPPLY_VAULT=.*/SUPPLY_VAULT=$CONTRACT_ADDRESS/" .env
    echo "✓ Updated SUPPLY_VAULT=$CONTRACT_ADDRESS"
  else
    echo "SUPPLY_VAULT=$CONTRACT_ADDRESS" >> .env
    echo "✓ Added SUPPLY_VAULT=$CONTRACT_ADDRESS"
  fi

  echo ""
  echo "Step 7: Verify Exchange Readiness Gate"
  echo "──────────────────────────────────────"
  bash scripts/exchange-readiness-gate.sh

  echo ""
  echo "╔═══════════════════════════════════════════════════════════════╗"
  echo "║              Deployment Process Complete ✓                   ║"
  echo "╚═══════════════════════════════════════════════════════════════╝"
  echo ""
  echo "Contract Address: $CONTRACT_ADDRESS"
  echo "Network: $NETWORK_NAME"
  echo ""
  echo "Next Steps:"
  echo "  1. Verify the contract on block explorer"
  echo "  2. Commit the deployment address: git add .env && git commit"
  echo "  3. Run exchange pack generation: npm run build:exchange"
  echo "  4. Submit to exchanges"
else
  echo "❌ Error: Deployment artifact not found"
  exit 1
fi
