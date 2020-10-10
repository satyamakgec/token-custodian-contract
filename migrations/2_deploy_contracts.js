const Custodian = artifacts.require("Custodian");

module.exports = function(deployer) {
  deployer.deploy(Custodian);
};
