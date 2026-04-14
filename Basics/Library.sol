// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library MathUtils {
    // Find the smaller of two numbers
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Find the larger of two numbers
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}

// ## 🔹 What if you used `external`?

// ```solidity
// function min(uint256 a, uint256 b) external pure returns (uint256)
// ```

// Now:

// * Function lives in a **deployed library contract**
// * Every call becomes an **external call**

// 👉 That means:

// * ❌ extra gas (CALL opcode)
// * ❌ slower execution
// * ❌ unnecessary complexity

// ---

// ## 🔹 When would you EVER use `external` in a library?

// Almost never, but edge cases:

// * If the library is **huge** and you want to:

//   * reduce contract bytecode size
//   * deploy logic separately

// Then Solidity uses a **linked library (like a shared contract)**
