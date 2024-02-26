const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const NFTStaking = await hre.ethers.getContractFactory("JEWS");
  const nftStaking = await NFTStaking.deploy();

  await nftStaking.deployed();

  console.log("Crowdfunding deployed to:", nftStaking.address);

  await hre.run("verify:verify", {
    address: nftStaking.address,
    contract: "contracts/NFTStaking.sol:NFTStaking",
    constructorArguments: [""],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
