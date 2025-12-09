import { network } from "hardhat";

const { ethers, networkName } = await network.connect({network: "sepolia"});
console.log(`Deploying MindchainNFT to ${networkName}...`);

const [deployer] = await ethers.getSigners();
console.log(await ethers.getSigners());

console.log("Deployer:", await deployer.getAddress());

const owner = "0x9e7dd23be678960fd1a4873c35a87d1ee4f3d63e";

const factory = await ethers.getContractFactory("MindchainNFT", deployer);

const contract = await factory.deploy(owner);

console.log("Waiting for the deployment tx to confirm");
await contract.waitForDeployment();

console.log("MindchainNFT address:", await contract.getAddress());

console.log("Deployment successful!");

