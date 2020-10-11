pragma solidity 0.6.0;

contract CustodianStorage {

    /// Mapping that hold the balance of holders on the basis of the give token address.
    /// token owner => token holder => balance.
    mapping (address => mapping(address => uint256)) public erc20CustodyBalanceOf;
    
    /// Mapping to hold the eth amount for the given address.
    /// ETH holder address (contract address or external account) => amount of ETH.
    mapping (address => uint256) public ethCustodyBalanceOf;
    
    /// Mapping to hold the address of allowed ERC20 tokens by the `this` contract.
    /// ERC20 token address => whether it is allowed or not.
    mapping (address => bool) public allowedToken;

    /// Keeping track of contract nonce to avoid replay attacks for the signed data.
    mapping (uint256 => bool) public signerNonce; 
    
}