const Custodian = artifacts.require("Custodian");
const CustodianProxy = artifacts.require("CustodianProxy.sol");

module.exports = function(deployer, network, accounts) {
  let admin;

  if (network === "development") {
    admin = accounts[0];
  } else if (network === "kovan" || network === "kovan-fork") {
    admin = ""; // Should be an address that owned the custodian contract.
  } else if (network === "mainnet" || network === "mainnet-fork") {
    admin = ""; // Should be an address that owned the custodian contract.
  }

  return deployer.deploy(Custodian).then(() => {
    return deployer.deploy(CustodianProxy, Custodian.address, admin, "0x8129fc1c").then(() => {
      console.log(`Address of the CustodianProxy Contract: ${CustodianProxy.address}`);
    })
  });
};
