const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("FlashLoanArbitrage", function () {
    let owner, user;
    let MockERC20, wethToken, tokenA, tokenB;
    let MockAavePoolAddressesProvider, mockAddressesProvider;
    let MockAavePool, mockAavePool;
    let MockUniswapV3Router, mockUniswapV3Router;
    let MockSushiSwapRouter, mockSushiSwapRouter;
    let FlashLoanArbitrage, flashLoanArbitrage;

    // Constants for test
    const WETH_ADDRESS_MAINNET_FOR_TEST = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"; // Real WETH for interface compatibility if needed
    const INITIAL_MINT_AMOUNT = ethers.utils.parseUnits("10000", 18); // 10,000 tokens

    beforeEach(async function () {
        [owner, user] = await ethers.getSigners();

        // Deploy MockERC20
        MockERC20 = await ethers.getContractFactory("MockERC20");
        wethToken = await MockERC20.deploy("Wrapped Ether", "WETH", 18);
        await wethToken.deployed();
        tokenA = await MockERC20.deploy("Token A", "TKA", 18);
        await tokenA.deployed();
        tokenB = await MockERC20.deploy("Token B", "TKB", 18);
        await tokenB.deployed();

        // Mint some tokens to owner for testing withdrawals and funding mocks
        await wethToken.mint(owner.address, INITIAL_MINT_AMOUNT);
        await tokenA.mint(owner.address, INITIAL_MINT_AMOUNT);
        await tokenB.mint(owner.address, INITIAL_MINT_AMOUNT);


        // Deploy MockAavePool
        MockAavePool = await ethers.getContractFactory("MockAavePool");
        mockAavePool = await MockAavePool.deploy();
        await mockAavePool.deployed();

        // Deploy MockAavePoolAddressesProvider
        MockAavePoolAddressesProvider = await ethers.getContractFactory("MockAavePoolAddressesProvider");
        mockAddressesProvider = await MockAavePoolAddressesProvider.deploy(mockAavePool.address);
        await mockAddressesProvider.deployed();

        // Deploy MockUniswapV3Router
        MockUniswapV3Router = await ethers.getContractFactory("MockUniswapV3Router");
        mockUniswapV3Router = await MockUniswapV3Router.deploy();
        await mockUniswapV3Router.deployed();

        // Deploy MockSushiSwapRouter
        MockSushiSwapRouter = await ethers.getContractFactory("MockSushiSwapRouter");
        // Assuming WETH_ADDRESS_MAINNET_FOR_TEST is a suitable address for the mock's WETH() function
        // For actual SushiSwap interactions, this WETH is important. For our mock, it's mostly for interface compliance.
        mockSushiSwapRouter = await MockSushiSwapRouter.deploy(wethToken.address);
        await mockSushiSwapRouter.deployed();

        // Deploy FlashLoanArbitrage
        FlashLoanArbitrage = await ethers.getContractFactory("FlashLoanArbitrage");
        flashLoanArbitrage = await FlashLoanArbitrage.deploy(
            mockAddressesProvider.address,
            wethToken.address, // Using our deployed mock WETH token as the WETH reference
            mockUniswapV3Router.address,
            mockSushiSwapRouter.address
        );
        await flashLoanArbitrage.deployed();
    });

    describe("Deployment and Initial State", function () {
        it("Should deploy all contracts successfully", function () {
            expect(wethToken.address).to.be.properAddress;
            expect(tokenA.address).to.be.properAddress;
            expect(tokenB.address).to.be.properAddress;
            expect(mockAavePool.address).to.be.properAddress;
            expect(mockAddressesProvider.address).to.be.properAddress;
            expect(mockUniswapV3Router.address).to.be.properAddress;
            expect(mockSushiSwapRouter.address).to.be.properAddress;
            expect(flashLoanArbitrage.address).to.be.properAddress;
        });

        it("Should set the correct owner", async function () {
            expect(await flashLoanArbitrage.owner()).to.equal(owner.address);
        });

        it("Should initialize in training mode", async function () {
            expect(await flashLoanArbitrage.isTrainingMode()).to.be.true;
        });

        it("Should have correct router and provider addresses set", async function () {
            expect(await flashLoanArbitrage.i_poolAddressesProvider()).to.equal(mockAddressesProvider.address);
            // Note: i_pool is derived inside FlashLoanArbitrage constructor, will be mockAavePool.address
            const derivedPoolAddress = await mockAddressesProvider.getPool();
            expect(await flashLoanArbitrage.i_pool()).to.equal(derivedPoolAddress);
            expect(await flashLoanArbitrage.i_weth()).to.equal(wethToken.address);
            expect(await flashLoanArbitrage.i_uniswapV3Router()).to.equal(mockUniswapV3Router.address);
            expect(await flashLoanArbitrage.i_sushiSwapRouter()).to.equal(mockSushiSwapRouter.address);
        });
    });

    describe("setTrainingMode", function () {
        it("Should allow owner to set training mode", async function () {
            await flashLoanArbitrage.connect(owner).setTrainingMode(false);
            expect(await flashLoanArbitrage.isTrainingMode()).to.be.false;
            await flashLoanArbitrage.connect(owner).setTrainingMode(true);
            expect(await flashLoanArbitrage.isTrainingMode()).to.be.true;
        });

        it("Should prevent non-owner from setting training mode", async function () {
            await expect(
                flashLoanArbitrage.connect(user).setTrainingMode(false)
            ).to.be.revertedWith("Not owner");
        });
    });

    describe("Withdrawals", function () {
        const withdrawAmount = ethers.utils.parseUnits("100", 18);

        beforeEach(async function() {
            // Send some tokens to the contract for withdrawal tests
            await tokenA.connect(owner).transfer(flashLoanArbitrage.address, withdrawAmount);
            await owner.sendTransaction({ to: flashLoanArbitrage.address, value: withdrawAmount }); // Send ETH
        });

        it("Should allow owner to withdraw ERC20 tokens", async function () {
            const initialOwnerBalance = await tokenA.balanceOf(owner.address);
            const contractBalance = await tokenA.balanceOf(flashLoanArbitrage.address);
            expect(contractBalance).to.equal(withdrawAmount);

            await flashLoanArbitrage.connect(owner).withdraw(tokenA.address);

            const finalOwnerBalance = await tokenA.balanceOf(owner.address);
            expect(await tokenA.balanceOf(flashLoanArbitrage.address)).to.equal(0);
            expect(finalOwnerBalance.sub(initialOwnerBalance)).to.equal(withdrawAmount);
        });

        it("Should prevent non-owner from withdrawing ERC20 tokens", async function () {
            await expect(
                flashLoanArbitrage.connect(user).withdraw(tokenA.address)
            ).to.be.revertedWith("Not owner");
        });

        it("Should revert ERC20 withdrawal if balance is zero", async function () {
            // Withdraw first, then try again
            await flashLoanArbitrage.connect(owner).withdraw(tokenA.address);
            await expect(
                flashLoanArbitrage.connect(owner).withdraw(tokenA.address)
            ).to.be.revertedWith("No tokens to withdraw");
        });

        it("Should allow owner to withdraw ETH", async function () {
            const initialOwnerEthBalance = await ethers.provider.getBalance(owner.address);
            const contractEthBalance = await ethers.provider.getBalance(flashLoanArbitrage.address);
            expect(contractEthBalance).to.equal(withdrawAmount);

            const tx = await flashLoanArbitrage.connect(owner).withdrawETH();
            const receipt = await tx.wait();
            const gasUsed = receipt.gasUsed.mul(tx.gasPrice);

            const finalOwnerEthBalance = await ethers.provider.getBalance(owner.address);
            expect(await ethers.provider.getBalance(flashLoanArbitrage.address)).to.equal(0);
            expect(initialOwnerEthBalance.sub(gasUsed).add(withdrawAmount)).to.equal(finalOwnerEthBalance);
        });

        it("Should prevent non-owner from withdrawing ETH", async function () {
            await expect(
                flashLoanArbitrage.connect(user).withdrawETH()
            ).to.be.revertedWith("Not owner");
        });

        it("Should revert ETH withdrawal if balance is zero", async function () {
            // Withdraw first, then try again
            await flashLoanArbitrage.connect(owner).withdrawETH();
             await expect(
                flashLoanArbitrage.connect(owner).withdrawETH()
            ).to.be.revertedWith("No ETH to withdraw");
        });
    });

    // More tests for requestFlashLoan and executeOperation will be added in subsequent subtasks
});
