// SPDX-License-Identifier: MIT
pragma solidity ^0.8.31;

import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice() internal view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        (, int256 price,,,) = priceFeed.latestRoundData();
        // returns price of ETH in USD with 8 decimal places
        // but wei's value in eth is denoted in 18 decimal places, so we need to multiply by 1e10
        return uint256(price * 1e10);
    }

    function getConversionRate(uint256 ethAmount) internal view returns(uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // as eth amount is in wei
        return ethAmountInUsd;
    }
}