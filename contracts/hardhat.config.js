import '@nomicfoundation/hardhat-toolbox';
import 'dotenv/config';

const rawPrivateKey = (process.env.PRIVATE_KEY || '').trim().replace(/^0x/, '');
const PRIVATE_KEY = /^[0-9a-fA-F]{64}$/.test(rawPrivateKey) ? `0x${rawPrivateKey}` : undefined;

/** @type import('hardhat/config').HardhatUserConfig */
export default {
  solidity: {
    version: '0.8.24',
    settings: {
      optimizer: { enabled: true, runs: 200 }
    }
  },
  networks: {
    hardhat: {},
    ethereum: {
      url: process.env.ETHEREUM_RPC_URL || '',
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    },
    bsc: {
      url: process.env.BSC_RPC_URL || '',
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : []
    }
  }
};
