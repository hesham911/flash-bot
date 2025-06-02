const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying FlashLoan Arbitrage Contract...");

  const FlashLoanArbitrage = await ethers.getContractFactory("FlashLoanArbitrage");
  const contract = await FlashLoanArbitrage.deploy();

  await contract.deployed();

  console.log("✅ Contract deployed to:", contract.address);
  console.log("📝 Transaction hash:", contract.deployTransaction.hash);

  // Save deployment info
  const fs = require('fs');
  const deploymentInfo = {
    contractAddress: contract.address,
    deploymentHash: contract.deployTransaction.hash,
    timestamp: new Date().toISOString(),
    network: "polygon"
  };

  fs.writeFileSync('./deployments.json', JSON.stringify(deploymentInfo, null, 2));
  console.log("📄 Deployment info saved to deployments.json");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
