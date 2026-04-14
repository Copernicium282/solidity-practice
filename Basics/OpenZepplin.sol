// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Import from npm package
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Import specific contracts
import {ERC721, IERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Import from local file
import "./Override.sol";

contract FeeToken is ERC20 {
    address public feeCollector;

    constructor(address _feeCollector) ERC20("Fee Token", "FEE") {
        feeCollector = _feeCollector;
        _mint(msg.sender, 1000000 * 10**18);
    }

    // Override the transfer function to add a 1% fee
    function transfer(address to, uint256 amount) public override returns (bool) {
        uint256 fee = amount / 100; // 1% fee
        uint256 netAmount = amount - fee;

        // Send fee to collector
        super.transfer(feeCollector, fee);

        // Send remaining amount to recipient
        return super.transfer(to, netAmount);
    }
}
