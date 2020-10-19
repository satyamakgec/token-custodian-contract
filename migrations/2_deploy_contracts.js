const Custodian = artifacts.require("Custodian");

module.exports = function(deployer) {
  let admin = ""; // Should be an address that owned the custodian contract.
  deployer.deploy(Custodian);
  deployer.deploy(Custodian.address, admin, 0x0);
};
