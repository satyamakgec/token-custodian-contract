pragma solidity 0.6.0;

import "./proxy/AdminUpgradeabilityProxy.sol";
import "./CustodianStorage.sol";

contract CustodianProxy is AdminUpgradeabilityProxy, CustodianStorage {

}