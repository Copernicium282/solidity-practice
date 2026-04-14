// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINUSD = 5e18;

    address[] public funders;
    mapping(address funder => uint256 amountFunded) public addressToAmountFunded;

    address public immutable i_owner;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        // require(msg.sender == i_owner, "Sender must be the Owner!!");
        if(msg.sender == i_owner) { revert NotOwner(); }
        _; // if this is in the last, the modifier is evaluated first and then the function code is executed
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINUSD, "Minimum funding value is 5 USD.");
        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;   
        }

        funders = new address[](0);

        // transfer method (DEPRECATED)
        // payable(msg.sender).transfer(address(this).balance);

        // send method (DEPRECATED)
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send Failed");

        // call method
        (bool callSuccess ,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");

    }

    receive() external payable { 
        fund();
    }

    fallback() external payable { 
        fund();
    }
}