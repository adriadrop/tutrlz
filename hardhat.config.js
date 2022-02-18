require("@nomiclabs/hardhat-waffle");

// Go to https://www.alchemyapi.io, sign up, create
// a new App in its dashboard, and replace "KEY" with its key
const ALCHEMY_API_KEY = "w4l-9r35-5c_GKdGw5kVDZQNK5ihP-pu";

// Replace this private key with your Ropsten account private key
// To export your private key from Metamask, open Metamask and
// go to Account Details > Export Private Key
// Be aware of NEVER putting real Ether into testing accounts
const RIKNEBY_PRIVATE_KEY = "a15b1829b9fc8980cdf4324a7ee839dddd7dfe36c14f94dd2513e45463e18bb0";

module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
        details: {
          yul: false
        }
      },
    },
  },
  networks: {
    rinkeby: {
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_API_KEY}`,
      accounts: [`${RIKNEBY_PRIVATE_KEY}`]
    },
    hardhat: {
      chainId: 31337
    }
  }
};
