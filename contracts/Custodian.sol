pragma solidity 0.6.2;

import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./proxy/ProxyAdmin.sol";
import "./CustodianStorage.sol";

contract Custodian is ProxyAdmin, CustodianStorage { 

    using SafeMath for uint256;
    using ECDSA for bytes32;
    
    /// Emitted when new custody token added. 
    event NewCustodyTokenAdded(address indexed _tokenAddress);
    /// Emitted when custody of the msg.sender get increased.
    event ERC20CustodyIncreased(address indexed _tokenAddress, address indexed _tokenHolder, uint256 _value);
    /// Emitted when the custody get released to the respective receiver.
    event ERC20CustodyReleased(address indexed _tokenAddress, address indexed _receiver, uint256 _value);
    /// Emitted when the custody of the msg.sender increased in ETH.
    event ETHCustodyIncreased(address indexed _tokenHolder, uint256 _value);
    /// Emitted when the custody of the ETH released.
    event ETHCustodyReleased(address indexed _receiver, uint256 _value);

    constructor () public  {
        initialized = true;
    }

    function initialize() public {
        require(!initialized, "Already initialized");
        initialized = true;
    }
    
    /// New token added. Only be called by the contract owner.
    //
    /// @param _tokenAddress Address of the ERC20 token.
    /// @dev Add new ERC20 token, So it can be used as the custody.
    function addCustodyToken(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        allowedToken[_tokenAddress] = true;
        emit NewCustodyTokenAdded(_tokenAddress);
    }
    
    /// Increase custody of `msg.sender`. 
    ///
    /// @param _tokenAddress Address of the ERC20 token.
    /// @param _value Amount of token `msg.sender` wants to provide the custody to the contract.
    function takeERC20Custody(address _tokenAddress, uint256 _value) public {
        _isTokenAndValueValid(_tokenAddress, _value);
        require(IERC20(_tokenAddress).balanceOf(msg.sender) >= _value, "Insufficient balance");
        require(IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _value), "TransferFrom failed");
        // Update the storage.
        erc20CustodyBalanceOf[_tokenAddress][msg.sender] = erc20CustodyBalanceOf[_tokenAddress][msg.sender].add(_value);
        emit ERC20CustodyIncreased(_tokenAddress, msg.sender, _value);
    }
    
    /// Release custody to the given `_receiver` address.
    ///
    /// @param _tokenAddress Address of the ERC20 token.
    /// @param _receiver address who recieves token.
    /// @param _value Amount of the tokens that need to be released to the given receiver.
    function releaseERC20Custody(address _tokenAddress, address _receiver, uint256 _value) external onlyOwner {
        _releaseERC20Custody(_tokenAddress, _receiver, _value);
    }
    
    /// Increase custody of `msg.sender`. 
    function takeETHCustody() external payable {
        require(msg.value > 0, "Value should be > 0");
        // Update the storage.
        ethCustodyBalanceOf[msg.sender] = ethCustodyBalanceOf[msg.sender].add(msg.value);
        emit ETHCustodyIncreased(msg.sender, msg.value);
    }
    
    /// Release custody to the given `_receiver` address.
    ///
    /// @param _receiver address who recieves token.
    /// @param _value Amount of the tokens that need to be released to the given receiver.
    function releaseETHCustody(address payable _receiver, uint256 _value) external onlyOwner {
        _releaseETHCustody(_receiver, _value);
    }
    
    /// Release custody of ERC20 to the given `_receiver` address using offchain sign data.
    /// Only owner is allowed to submit the offchain sign data.
    ///
    /// @param _tokenAddress Address of the ERC20 token.
    /// @param _receiver address who recieves token.
    /// @param _value Amount of the tokens that need to be released to the given receiver.
    function releaseERC20CustodyWithData(address _tokenAddress, address _receiver, uint256 _value, bytes calldata _data) external {
        address tokenAddress;
        address targetAddress;
        address receiver;
        uint256 value;
        uint256 nonce;
        bytes memory signature;
        (tokenAddress, targetAddress, receiver, value, nonce, signature) = abi.decode(_data, (address, address, address, uint256, uint256, bytes));
        require(receiver == _receiver, "Invalid address");
        require(targetAddress == address(this), "Invalid target address");
        require(_value == value, "Invalid amount of tokens");
        require(tokenAddress == _tokenAddress, "Invalid token address");
        require(signerNonce[nonce] == false, "Already used signature");
        bytes32 hash = keccak256(abi.encodePacked(address(this), _tokenAddress, _receiver, _value, nonce));
        require(hash.toEthSignedMessageHash().recover(signature) == owner(), "Unauthorised signer");
        // Invalidate the nonce
        signerNonce[nonce] = true;
        _releaseERC20Custody(_tokenAddress, _receiver, _value);
    }

    /// Release custody of ETH to the given `_receiver` address using offchain sign data.
    /// Only owner is allowed to submit the offchain sign data.
    ///
    /// @param _receiver address who recieves token.
    /// @param _value Amount of the tokens that need to be released to the given receiver.
    function releaseETHCustodyWithData(address payable _receiver, uint256 _value, bytes calldata _data) external {
        address targetAddress;
        address receiver;
        uint256 value;
        uint256 nonce;
        bytes memory signature;
        (targetAddress, receiver, value, nonce, signature) = abi.decode(_data, (address, address, uint256, uint256, bytes));
        require(receiver == _receiver, "Invalid address");
        require(targetAddress == address(this), "Invalid target address");
        require(_value == value, "Invalid amount of tokens");
        require(signerNonce[nonce] == false, "Already used signature");
        bytes32 hash = keccak256(abi.encodePacked(address(this), _receiver, _value, nonce));
        require(hash.toEthSignedMessageHash().recover(signature) == owner(), "Unauthorised signer");
        // Invalidate the nonce
        signerNonce[nonce] = true;
        _releaseETHCustody(_receiver, _value);
    }

    /// Internal function to release ETH custody.
    function _releaseETHCustody(address payable _receiver, uint256 _value) internal {
        require(_receiver != address(0), "0x0 is not allowed");
        require(_value > 0, "Value should be > 0");
        uint256 current_custody = ethCustodyBalanceOf[_receiver];
        require(current_custody >= _value, "Insufficient balance");
        // Not using safe math here as we already checked that `current_custody` >= _value.
        ethCustodyBalanceOf[_receiver] = current_custody - _value;
        _receiver.transfer(_value);
        emit ETHCustodyReleased(_receiver, _value);
    }

    /// Internal function to release ERC20 custody.
    function _releaseERC20Custody(address _tokenAddress, address _receiver, uint256 _value) internal {
        require(_receiver != address(0), "0x0 is not allowed");
        _isTokenAndValueValid(_tokenAddress, _value);
        uint256 current_custody = erc20CustodyBalanceOf[_tokenAddress][_receiver];
        require( current_custody >= _value, "Insufficient balance");
         // Not using safe math here as we already checked that `current_custody` >= _value.
        erc20CustodyBalanceOf[_tokenAddress][_receiver] = current_custody - _value;
        require(IERC20(_tokenAddress).transfer(_receiver, _value), "Transfer fail");
        emit ERC20CustodyReleased(_tokenAddress, _receiver, _value);
    }
    
    /// Internal function to validate given parameters.
    function _isTokenAndValueValid(address _tokenAddress, uint256 _value) internal view {
        require(_value > uint256(0), "Value should be > 0");
        require(allowedToken[address(_tokenAddress)], "Token is not allowed");
    }
}