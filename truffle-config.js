module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*", // Match any network id
      gas: 5000000
    }
  },
  compilers: {
    compilers: {
      solc: {
        version: "^0.6.0", // A version or constraint - Ex. "^0.5.0". Can also be set to "native" to use a native solc
        parser: "solcjs",  // Leverages solc-js purely for speedy parsing
        settings: {
          optimizer: {
            enabled: true,
            runs: 200   // Optimize for how many times you intend to run the code
          },
        }
      }
    }
  }
};
