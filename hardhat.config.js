require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
// const { ACCOUNT_PRIVATE_KEY,ALCHEMY_KEY } = process.env;

module.exports = {
  solidity: {
    version: "0.8.18",
    settings: {
      optimizer: {
        runs: 200,
        enabled: true,
        details: {
          yulDetails: {
            optimizerSteps: "u",
          },
        },
      },
      viaIR: true,
    },
  },
  // defaultNetwork: "rinkeby",
  paths: {
    artifacts: "./client/artifacts",
  },
  networks: {
    hardhat: {
      chainId: 5,
    },
    goerli: {
      url: `https://ethereum-goerli.publicnode.com/`,
      accounts: [`0x${8ece7af4afdee671ac82bc2b283fda95e55f646c589537e64f98cf349d92945b}`],
    },
    // rinkeby: {
    //   url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_KEY}`,
    //   accounts: [`0x${ACCOUNT_PRIVATE_KEY}`]
    // }
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    // P8SEC5V14GPAY91W9EF58UF1GVTRXY276K

    apiKey: {
      goerli: "9R4FZ7QN9ZE8BICXFN3N1UUCNHNW51HBD1",
      bsc: "P8SEC5V14GPAY91W9EF58UF1GVTRXY276K",
      bscTestnet: "P8SEC5V14GPAY91W9EF58UF1GVTRXY276K",
      rinkeby: "E29Y4T9JQV3JDH75CCTKRJ7GJKV1CI5QJE",
      mainnet: "9R4FZ7QN9ZE8BICXFN3N1UUCNHNW51HBD1",
      polygon: "M4V8ERWDRTRVKUZ2324MFDRXFABPII1JYD",
    },
  },
};
