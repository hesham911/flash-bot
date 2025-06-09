// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title FlashLoan Arbitrage Contract
/// @notice Executes Aave flash loans and arbitrage across Uniswap V3 and SushiSwap
contract FlashLoanArbitrage is FlashLoanSimpleReceiverBase, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum Dex { UniswapV3, SushiSwap }

    ISwapRouter public immutable uniswapRouter;
    IUniswapV2Router02 public immutable sushiRouter;
    address public owner;

    mapping(address => bool) public supportedTokens;

    event TradeExecuted(address indexed asset, uint256 amount, uint256 profit, Dex dex);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        IPoolAddressesProvider provider,
        address _uniswapRouter,
        address _sushiRouter,
        address[] memory tokens
    ) FlashLoanSimpleReceiverBase(provider) {
        owner = msg.sender;
        uniswapRouter = ISwapRouter(_uniswapRouter);
        sushiRouter = IUniswapV2Router02(_sushiRouter);
        for (uint i = 0; i < tokens.length; i++) {
            supportedTokens[tokens[i]] = true;
        }
    }

    function setSupportedToken(address token, bool enabled) external onlyOwner {
        supportedTokens[token] = enabled;
    }

    /// @notice Initiate a flash loan and arbitrage
    /// @param asset Token to borrow
    /// @param amount Amount to borrow
    /// @param dex Which DEX to use
    /// @param intermediate Token to swap through
    /// @param fee Pool fee tier (Uniswap V3)
    function initiateFlashloan(
        address asset,
        uint256 amount,
        Dex dex,
        address intermediate,
        uint24 fee
    ) external onlyOwner nonReentrant {
        require(supportedTokens[asset] && supportedTokens[intermediate], "Unsupported token");
        bytes memory params = abi.encode(dex, intermediate, fee);
        POOL.flashLoanSimple(address(this), asset, amount, params, 0);
    }

    /// @inheritdoc FlashLoanSimpleReceiverBase
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        require(msg.sender == address(POOL), "Caller must be pool");
        require(initiator == address(this), "Bad initiator");

        (Dex dex, address intermediate, uint24 fee) = abi.decode(params, (Dex, address, uint24));

        if (dex == Dex.UniswapV3) {
            _arbitrageUniswapV3(asset, amount, intermediate, fee);
        } else {
            _arbitrageSushiSwap(asset, amount, intermediate);
        }

        uint256 totalOwed = amount + premium;
        uint256 balance = IERC20(asset).balanceOf(address(this));
        require(balance >= totalOwed, "Insufficient balance");
        uint256 profit = balance - totalOwed;

        IERC20(asset).approve(address(POOL), totalOwed);
        if (profit > 0) {
            IERC20(asset).safeTransfer(owner, profit);
        }

        emit TradeExecuted(asset, amount, profit, dex);
        return true;
    }

    function _arbitrageUniswapV3(
        address asset,
        uint256 amount,
        address intermediate,
        uint24 fee
    ) internal {
        IERC20(asset).approve(address(uniswapRouter), amount);
        ISwapRouter.ExactInputSingleParams memory p1 = ISwapRouter.ExactInputSingleParams({
            tokenIn: asset,
            tokenOut: intermediate,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        uint256 intermAmount = uniswapRouter.exactInputSingle(p1);

        IERC20(intermediate).approve(address(uniswapRouter), intermAmount);
        ISwapRouter.ExactInputSingleParams memory p2 = ISwapRouter.ExactInputSingleParams({
            tokenIn: intermediate,
            tokenOut: asset,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: intermAmount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });
        uniswapRouter.exactInputSingle(p2);
    }

    function _arbitrageSushiSwap(
        address asset,
        uint256 amount,
        address intermediate
    ) internal {
        IERC20(asset).approve(address(sushiRouter), amount);
        address[] memory path1 = new address[](2);
        path1[0] = asset;
        path1[1] = intermediate;
        sushiRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amount,
            0,
            path1,
            address(this),
            block.timestamp
        );

        uint256 intermAmount = IERC20(intermediate).balanceOf(address(this));
        IERC20(intermediate).approve(address(sushiRouter), intermAmount);
        address[] memory path2 = new address[](2);
        path2[0] = intermediate;
        path2[1] = asset;
        sushiRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            intermAmount,
            0,
            path2,
            address(this),
            block.timestamp
        );
    }

    function withdrawToken(address token) external onlyOwner {
        uint256 bal = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(owner, bal);
    }
}
