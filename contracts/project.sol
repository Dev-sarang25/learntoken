// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LearnToken
 * @dev A simple ERC-20 token implementation for learning purposes
 * Demonstrates basic token functionality including:
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
     * @dev Constructor sets the initial owner and mints initial supply
     * @param _initialSupply The initial token supply (in tokens, not wei)
     */
    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        _mint(msg.sender, _initialSupply * 10 ** decimals);
    }

    /**
     * @dev Transfer tokens from sender to recipient
     * @param _to The recipient address
     * @param _value The amount to transfer
     * @return success True if transfer succeeded
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
     * @dev Public mint function (owner only)
     * @param _to The recipient address
     * @param _amount The amount to mint (in tokens, not wei)
     */
    function mint(address _to, uint256 _amount) public {
        require(msg.sender == owner, "Only owner can mint");
        _mint(_to, _amount * 10 ** decimals);
    }

    /**
     * @dev Internal mint logic
     * @param _to The recipient address
     * @param _amount The amount to mint (already adjusted for decimals)
     */
    function _mint(address _to, uint256 _amount) internal {
        require(_to != address(0), "Cannot mint to zero address");

        totalSupply += _amount;
        balanceOf[_to] += _amount;

        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev Get the balance of an account
     * @param _account The account to query
     * @return balance The token balance
     */
    function getBalance(address _account) public view returns (uint256 balance) {
        return balanceOf[_account];
    }
}
