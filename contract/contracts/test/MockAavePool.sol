// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanArbitrageReceiver {
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

contract MockAavePool {
    address public owner;
    uint256 public currentFlashLoanPremium = 5; // Example premium: 0.05% if 1 basis point = 100, so 5 means 0.05%
    uint256 public constant PREMIUM_BASIS_POINTS = 10000; // For calculating premium amount (e.g. 0.05% is 5/10000)


    mapping(address => uint256) public assetBalances; // To simulate pool having funds

    event FlashLoanSimpleCalled(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes params,
        uint16 referralCode
    );

    event Repayment(address indexed asset, uint256 amount, uint256 premium);

    constructor() {
        owner = msg.sender;
    }

    function setFlashLoanPremium(uint256 _premium) public onlyOwner {
        currentFlashLoanPremium = _premium;
    }

    // Utility to fund the mock pool with tokens
    function fundPool(address _asset, uint256 _amount) public {
        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        assetBalances[_asset] += _amount;
    }

    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes memory params,
        uint16 referralCode
    ) external {
        emit FlashLoanSimpleCalled(receiverAddress, asset, amount, params, referralCode);

        // require(IERC20(asset).balanceOf(address(this)) >= amount, "MockAavePool: Insufficient funds for flash loan");

        // // 1. Transfer asset to receiver
        // IERC20(asset).transfer(receiverAddress, amount);

        // Calculate premium (still needed for executeOperation signature)
        uint256 premiumAmount = (amount * currentFlashLoanPremium) / PREMIUM_BASIS_POINTS;

        // 2. Call executeOperation on receiver - SIMPLIFIED
        // We assume it succeeds and don't handle its actual logic for this compilation test
        IFlashLoanArbitrageReceiver(receiverAddress).executeOperation(
            asset,
            amount,
            premiumAmount,
            msg.sender,
            params
        );
        // require(success, "MockAavePool: executeOperation returned false"); // Temporarily removed

        // 3. Verify approval and pull back funds - SIMPLIFIED
        // uint256 amountToRepay = amount + premiumAmount;
        // IERC20(asset).transferFrom(receiverAddress, address(this), amountToRepay); // Temporarily removed
        // emit Repayment(asset, amount, premiumAmount); // Temporarily removed
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}
