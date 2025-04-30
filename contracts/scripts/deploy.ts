import { ethers } from "hardhat";

async function main() {
  // Deploy DecentralizedIdentityFactory
  const Factory = await ethers.getContractFactory("DecentralizedIdentityFactory");
  const factory = await Factory.deploy();
  await factory.waitForDeployment(); // ✅ Replace `.deployed()` with `.waitForDeployment()`
  
  console.log("DecentralizedIdentityFactory deployed to:", await factory.getAddress());

  // The NFT and FileSharing contracts are deployed by the factory
  console.log("DID NFT contract deployed to:", await factory.didNFTContract());
  console.log("File Sharing contract deployed to:", await factory.fileSharingContract());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
