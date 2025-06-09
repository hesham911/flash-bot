// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract FlashLoanArbitrage is ReentrancyGuard {
    IPool public immutable i_pool;
    address public immutable i_poolAddressesProvider;
    address public immutable i_weth; // Polygon WETH: 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619
    ISwapRouter public immutable i_uniswapV3Router;
    IUniswapV2Router02 public immutable i_sushiSwapRouter;

    address public owner;
    bool public isTrainingMode = true;

    event TradeExecuted(
        address indexed initiator, // Changed from tokenOrInitiator to always be initiator
        uint256 loanAmount,       // Original loan amount
        int256 netProfit         // Net profit (can be negative)
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(
        address _poolAddressesProvider,
        address _wethAddress,
        address _uniswapV3RouterAddress,
        address _sushiSwapRouterAddress
    ) {
        owner = msg.sender;
        i_poolAddressesProvider = _poolAddressesProvider;
        i_pool = IPool(IPoolAddressesProvider(_poolAddressesProvider).getPool());
        i_weth = _wethAddress;
        i_uniswapV3Router = ISwapRouter(_uniswapV3RouterAddress);
        i_sushiSwapRouter = IUniswapV2Router02(_sushiSwapRouterAddress);
    }

    function setTrainingMode(bool _isTraining) external onlyOwner {
        isTrainingMode = _isTraining;
    }

    function requestFlashLoan(
        address _loanToken,         // This is 'asset' from executeOperation
        uint256 _loanAmount,
        uint8 _dexSelector1,        // For swap 1: asset -> intermediateToken
        bytes calldata _dexParams1,  // Encoded params for DEX1
        uint8 _dexSelector2,        // For swap 2: intermediateToken -> asset
        bytes calldata _dexParams2,  // Encoded params for DEX2
        address _intermediateToken  // The token that is the output of swap1 and input of swap2
    ) external nonReentrant {
        bytes memory paramsForAave = abi.encode(
            _dexSelector1, _dexParams1,
            _dexSelector2, _dexParams2,
            _intermediateToken
        );

        i_pool.flashLoanSimple(
            address(this),
            _loanToken,
            _loanAmount,
            paramsForAave,
            0
        );
    }

    function _uniswapV3Swap(
        address _tokenIn,
        address _tokenOut,
        uint24 _poolFee,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) internal returns (uint256 amountOut) {
        IERC20(_tokenIn).approve(address(i_uniswapV3Router), _amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: _tokenIn,
            tokenOut: _tokenOut,
            fee: _poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: _amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        amountOut = i_uniswapV3Router.exactInputSingle(params);
        return amountOut;
    }

    function _sushiSwap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMinimum
    ) internal returns (uint256 amountOut) { // Changed recipient to address(this) and return type
        IERC20(_tokenIn).approve(address(i_sushiSwapRouter), _amountIn);

        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint[] memory amounts = i_sushiSwapRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMinimum,
            path,
            address(this),
            block.timestamp
        );
        return amounts[amounts.length - 1]; // Return only the output amount
    }

    function executeOperation(
        address asset,          // This is _loanToken
        uint256 amount,         // This is _loanAmount
        uint256 premium,
        address initiator,      // Who called requestFlashLoan
        bytes calldata paramsFromFlashLoan
    ) external returns (bool) {
        require(msg.sender == address(i_pool), "Caller must be Aave Pool");

        uint256 amountToRepay = amount + premium;

        if (isTrainingMode) {
            emit TradeExecuted(initiator, amount, 0);
            IERC20(asset).approve(address(i_pool), amountToRepay); // Approve repayment even in training
            return true;
        }

        // ---- Production Mode ----
        (
            uint8 dexSelector1, bytes memory dexParams1,
            uint8 dexSelector2, bytes memory dexParams2,
            address intermediateToken
        ) = abi.decode(paramsFromFlashLoan, (uint8, bytes, uint8, bytes, address));

        // Execute Swap 1 (asset -> intermediateToken)
        uint256 amountIntermediateToken;
        if (dexSelector1 == 0) { // Uniswap V3 for Swap 1
            (address tokenOutUni1, uint24 poolFeeUni1, uint256 amountOutMinUni1) = abi.decode(dexParams1, (address, uint24, uint256));
            require(tokenOutUni1 == intermediateToken, "Swap1: tokenOutUni1 mismatch");
            amountIntermediateToken = _uniswapV3Swap(asset, intermediateToken, poolFeeUni1, amount, amountOutMinUni1);
        } else if (dexSelector1 == 1) { // SushiSwap for Swap 1
            (address tokenOutSushi1, uint256 amountOutMinSushi1) = abi.decode(dexParams1, (address, uint256));
            require(tokenOutSushi1 == intermediateToken, "Swap1: tokenOutSushi1 mismatch");
            amountIntermediateToken = _sushiSwap(asset, intermediateToken, amount, amountOutMinSushi1);
        } else {
            revert("Invalid DEX selector for Swap 1");
        }
        require(amountIntermediateToken > 0, "Swap1: Insufficient output");

        // Execute Swap 2 (intermediateToken -> asset)
        uint256 finalAssetAmount;
        if (dexSelector2 == 0) { // Uniswap V3 for Swap 2
            (address tokenOutUni2, uint24 poolFeeUni2, uint256 amountOutMinUni2) = abi.decode(dexParams2, (address, uint24, uint256));
            require(tokenOutUni2 == asset, "Swap2: tokenOutUni2 mismatch");
            finalAssetAmount = _uniswapV3Swap(intermediateToken, asset, poolFeeUni2, amountIntermediateToken, amountOutMinUni2);
        } else if (dexSelector2 == 1) { // SushiSwap for Swap 2
            (address tokenOutSushi2, uint256 amountOutMinSushi2) = abi.decode(dexParams2, (address, uint256));
            require(tokenOutSushi2 == asset, "Swap2: tokenOutSushi2 mismatch");
            finalAssetAmount = _sushiSwap(intermediateToken, asset, amountIntermediateToken, amountOutMinSushi2);
        } else {
            revert("Invalid DEX selector for Swap 2");
        }
        require(finalAssetAmount > 0, "Swap2: Insufficient output");

        // Profit Calculation & Repayment
        int256 netProfit;
        if (finalAssetAmount >= amountToRepay) {
            netProfit = int256(finalAssetAmount - amountToRepay);
        } else {
            netProfit = -int256(amountToRepay - finalAssetAmount);
        }

        emit TradeExecuted(initiator, amount, netProfit);

        require(finalAssetAmount >= amountToRepay, "Arbitrage failed: Insufficient funds to repay loan + premium");

        IERC20(asset).approve(address(i_pool), amountToRepay);

        // Profit Transfer
        if (netProfit > 0) {
            if (asset != i_weth) { // If profit is in a token other than WETH, transfer it.
                IERC20(asset).transfer(owner, uint256(netProfit));
            }
            // If asset is WETH, profit (as WETH) stays in contract for withdrawal via withdraw() or withdrawETH().
        }

        return true;
    }

    function withdraw(address _tokenAddress) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "No tokens to withdraw");
        bool sent = token.transfer(owner, tokenBalance);
        require(sent, "Token transfer failed");
    }

    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool sent, ) = owner.call{value: balance}("");
        require(sent, "ETH transfer failed");
    }
}
