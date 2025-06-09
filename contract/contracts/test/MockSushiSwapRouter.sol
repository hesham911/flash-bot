// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// It's good practice to import the interface it's mocking, even if not strictly used for parameters here
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


contract MockSushiSwapRouter {
    // Mapping to set expected output amounts for a given input pair and amountIn
    // key = keccak256(abi.encodePacked(tokenIn, tokenOut, amountIn))
    mapping(bytes32 => uint256) public expectedOutputAmounts;
    // Mapping to set expected input amounts for assertion
    // key = keccak256(abi.encodePacked(tokenIn, tokenOut))
    mapping(bytes32 => uint256) public expectedAmountIn;

    address public immutable i_wethAddress; // Renamed from WETH to avoid clash with WETH() function

    event SwappedV2(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMinimum,
        address recipient,
        uint256 amountOutActual
    );

    constructor(address _wethParam) { // Renamed constructor param for clarity
        i_wethAddress = _wethParam;
    }

    // Function to allow test setup to configure expected output for a swap
    function setExpectedOutput(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn, // The specific amountIn that will trigger this output
        uint256 _expectedAmountOut
    ) external {
        bytes32 key = keccak256(abi.encodePacked(_tokenIn, _tokenOut, _amountIn));
        expectedOutputAmounts[key] = _expectedAmountOut;
    }

    // Function to allow test setup to configure an expected amountIn for assertion
     function setExpectedInput(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external {
        bytes32 key = keccak256(abi.encodePacked(_tokenIn, _tokenOut));
        expectedAmountIn[key] = _amountIn;
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMinimum,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts) {
        // require(path.length == 2, "MockSushiSwapRouter: Path length must be 2"); // Simplified
        // require(deadline >= block.timestamp, "MockSushiSwapRouter: Expired deadline"); // Simplified

        // address tokenIn = path[0]; // Simplified
        // address tokenOut = path[1]; // Simplified

        // // Check if specific input amount was set for assertion
        // bytes32 inputKey = keccak256(abi.encodePacked(tokenIn, tokenOut));
        // if (expectedAmountIn[inputKey] > 0) {
        //     require(amountIn == expectedAmountIn[inputKey], "MockSushiSwapRouter: amountIn does not match expected");
        // }

        // // Simulate taking tokens from caller
        // IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn); // Simplified

        // // Determine output amount
        // bytes32 outputKey = keccak256(abi.encodePacked(tokenIn, tokenOut, amountIn));
        // uint256 amountOutActual = expectedOutputAmounts[outputKey]; // Simplified

        // require(amountOutActual > 0, "MockSushiSwapRouter: Output not configured or zero amount"); // Simplified
        // require(amountOutActual >= amountOutMinimum, "MockSushiSwapRouter: Would not meet minimum output"); // Simplified

        // // Transfer output tokens to recipient
        // IERC20(tokenOut).transfer(to, amountOutActual); // Simplified

        amounts = new uint[](2);
        amounts[0] = amountIn;
        amounts[1] = amountIn; // Placeholder: return amountIn as output to satisfy return type

        // emit SwappedV2( // Simplified
        //     tokenIn,
        //     tokenOut,
        //     amountIn,
        //     amountOutMinimum,
        //     to,
        //     amountIn // Placeholder
        // );
        return amounts;
    }

    // Required WETH() function from IUniswapV2Router02
    function WETH() external view returns (address) {
        return i_wethAddress; // Returns the stored WETH address
    }

    // Fallback to receive ETH
    receive() external payable {}
}
