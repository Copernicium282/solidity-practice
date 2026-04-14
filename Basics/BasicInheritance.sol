// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Base contract with core functionality
contract BaseToken {
    string public name;
    uint256 public totalSupply;

    constructor(string memory _name) {
        name = _name;
        totalSupply = 1000000;
    }

    function getInfo() public virtual view returns (string memory) {
        return string.concat("Token: ", name);
    }
}

// Enhanced contract that inherits and extends BaseToken
contract GoldToken is BaseToken {
    constructor() BaseToken("Gold Token") {}
    
    // Add new functionality
    function getSymbol() public pure returns (string memory) {
        return "GLD";
    }
}