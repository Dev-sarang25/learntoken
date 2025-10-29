// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * title LearnToken
 * A simple ERC-20 token implementation for learning purposes
 * This contract should demonstrates basic token functionality including:
 * - Minting tokens
 * - Transfers between accounts
 */
contract LearnToken {
    // Token metadata
    string public name = "Learn Token";
    string public symbol = "LEARN";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // Balance mapping: address => token balance
    mapping(address => uint256) public balanceOf;

    // Owner of the contract (for minting)
    address public owner;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 amount);

    /**
     * Constructor sets the initial owner and mints initial supply
     * para initialSupply The initial token supply (in tokens, not wei)
     */
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, _initialSupply * 10**decimals);
    }

    /**
     * Transfer tokens from sender to recipient
     * para _to The recipient address
     * para _value The amount to transfer
     * return success True if transfer succeeded
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
     * Internal mint function
     * para to The recipient address
     * para amount The amount to mint
     */
    function _mint(address _to, uint256 _amount) internal {
        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * Get the balance of an account
     * para account The account to query
     * return balance The token balance
     */
    function getBalance(address _account) public view returns (uint256 balance) {
        return balanceOf[_account];
    }
}