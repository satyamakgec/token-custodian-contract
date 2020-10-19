pragma solidity 0.6.2;

import "./proxy/AdminUpgradeabilityProxy.sol";
import "./CustodianStorage.sol";

contract CustodianProxy is AdminUpgradeabilityProxy, CustodianStorage {

    constructor(address _implementation, address _admin, bytes memory _data) 
    AdminUpgradeabilityProxy(_implementation, _admin, _data)
    public
    {

    }
}