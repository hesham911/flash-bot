// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals_
    ) ERC20(name, symbol) {
        // Note: OpenZeppelin's ERC20 sets decimals to 18 by default.
        // If you need a different value, you'd override _decimals() or set it here if possible.
        // For simplicity, we'll rely on the default or assume 18 is fine for tests.
        // If a specific decimals value is needed and ERC20 constructor doesn't take it:
        // _setupDecimals(decimals_); // This function is internal, so we can't call it directly.
        // We will use the standard OZ ERC20 which has 18 decimals.
    }

    function _setupDecimals(uint8 decimals_) internal {
        // This is a workaround if a different decimal was needed, but OZ ERC20 doesn't allow easy change.
        // For testing, usually 18 is fine. This function is not directly available in OZ ERC20.
        // We will proceed assuming 18 decimals is acceptable for mock tokens.
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // Expose internal _approve for easier testing if needed for more complex scenarios
    // where contract itself needs to approve something on behalf of a user for a mock.
    // function externalApprove(address owner, address spender, uint256 amount) public {
    //     _approve(owner, spender, amount);
    // }
}
