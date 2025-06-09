// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMockAavePool {
    // Minimal interface needed if MockAavePool is not fully defined elsewhere for typecasting
    function mockPoolFunction() external returns (bool); // Placeholder
}

contract MockAavePoolAddressesProvider {
    address private poolAddress;

    constructor(address _poolAddress) {
        poolAddress = _poolAddress;
    }

    function setPoolAddress(address _newPoolAddress) public {
        poolAddress = _newPoolAddress;
    }

    function getPool() external view returns (address) {
        return poolAddress;
    }
}
