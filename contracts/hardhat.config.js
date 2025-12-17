require('dotenv').config();
require('@nomicfoundation/hardhat-toolbox');

const PRIVATE_KEY = process.env.PRIVATE_KEY ? `0x${process.env.PRIVATE_KEY.replace(/^0x/, '')}` : undefined;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
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
