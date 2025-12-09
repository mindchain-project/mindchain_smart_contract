import { expect } from "chai";
import { network } from "hardhat";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const { ethers } = await network.connect();

// Fonction de setup du déploiement du smart contract
async function setUpContract() {
  // Liste des adresses whitelisted pour le test
  const [owner] = await ethers.getSigners();
  const certifier = await ethers.deployContract(
    "MindchainNFT", 
    [ owner.address]
  );
  await certifier.waitForDeployment();
  return { certifier, owner };
}

async function setUpContractWithUser() {
  const {certifier, owner} = await setUpContract();
  const [user] = await ethers.getSigners();
  return { certifier, owner, user };
  }

describe("Mindchain NFT Contract", function () {
  describe("1. Certify setup", function () {

    let certifier: any;
    let owner: any;

    beforeEach(async function () {
      const setup = await setUpContract();
      certifier = setup.certifier;
      owner = setup.owner;
    });

    // 1.Le owner du contrat est le deployerrtif
    it("Contract owner should be deployer", async function () {
        expect(await certifier.owner()).to.equal(owner.address);
    });
    // 2. Vérification du nom et du symbole du token
    it("Should have correct name and symbol", async function () {
        expect(await certifier.name()).to.equal("Mindchain");
        expect(await certifier.symbol()).to.equal("MDC");
    });
    // 3. Vérification qu'aucun NFT n'est minté au déploiement
    it("Should not mint any NFT at deployment", async function () {
        const nextTokenId = await certifier.totalSupply();
        expect(nextTokenId).to.equal(0);
    });
  });

  describe("2. Minting NFTs", function () {

    let certifier: any;
    let owner: any;
    let user: any;

    beforeEach(async function () {
      const setup = await setUpContractWithUser();
      certifier = setup.certifier;
      owner = setup.owner;
      user = setup.user;
    });
    // 1. Un utilisateur peut minter un NFT
    it("User should mint a NFT", async function () {
        const mintTx = await certifier.mintMindchain(
            user.address,
            "bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmve"
        );
        await mintTx.wait();
        const nextTokenId = await certifier.totalSupply();
        expect(nextTokenId).to.equal(1);
    });
  });
});
