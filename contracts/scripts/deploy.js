import 'dotenv/config';
import hre from 'hardhat';
import fs from 'fs';
const { ethers } = hre;

function scaleSupply(amountStr, decimals) {
  return ethers.parseUnits(String(amountStr), decimals);
}

async function main() {
  const name = process.env.TOKEN_NAME || 'SpiralCoin';
  const symbol = process.env.TOKEN_SYMBOL || 'SPRC';
  const decimals = process.env.TOKEN_DECIMALS ? parseInt(process.env.TOKEN_DECIMALS, 10) : 18;
  const initialSupplyWhole = process.env.TOKEN_INITIAL_SUPPLY || '1000000000';
  const owner = (process.env.TOKEN_OWNER && process.env.TOKEN_OWNER.length > 0)
    ? process.env.TOKEN_OWNER
    : (await ethers.getSigners())[0].address;

  console.log(`[Deploy] Network: ${hre.network.name}`);
  console.log(`[Deploy] Deployer: ${(await ethers.getSigners())[0].address}`);
  console.log(`[Deploy] Owner:    ${owner}`);
  console.log(`[Deploy] Token:    ${name} (${symbol}), decimals=${decimals}`);
  console.log(`[Deploy] Supply:   ${initialSupplyWhole} (whole tokens)`);

  const supplyScaled = scaleSupply(initialSupplyWhole, decimals);
  const Factory = await ethers.getContractFactory('SPRC');
  const token = await Factory.deploy(name, symbol, decimals, owner, supplyScaled);
  await token.waitForDeployment();

  const addr = await token.getAddress();
  console.log(`[Deploy] Deployed SPRC at: ${addr}`);

  // Output a small JSON artifact for the exchange pack or docs
  const outDir = `${process.cwd()}/build`;
  try { fs.mkdirSync(outDir, { recursive: true }); } catch {}
  const out = {
    network: hre.network.name,
    address: addr,
    name,
    symbol,
    decimals,
    initialSupply: initialSupplyWhole
  };
  fs.writeFileSync(`${outDir}/deployment_${hre.network.name}.json`, JSON.stringify(out, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
