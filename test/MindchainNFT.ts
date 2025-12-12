import { expect, use } from "chai";
import { network } from "hardhat";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const { ethers } = await network.connect();

// Fonction de setup du déploiement du smart contract
async function setUpContract() {
  const signers = await ethers.getSigners();
  const owner = signers[0];
  const whitelist = signers.slice(0, 5).map(signer => signer.address);
  const uri = "bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmve";
  const merkleTree = StandardMerkleTree.of(
    whitelist.map(address => [address]),
    ["address"]
  );
  const root = merkleTree.root;
  const tokenName = "Mindchain";
  const tokenSymbol = "MDC";
  const contract = await ethers.deployContract(
    "MindchainNFT", 
    [ owner.address, uri, root, tokenName, tokenSymbol]
  );
  await contract.waitForDeployment();
  return { contract, owner, whitelist, merkleTree, tokenName, tokenSymbol };
}


describe("Mindchain NFT Contract", function () {
  describe("1. Contract setup", function () {

    let contract: any;
    let owner: any;
    let whitelist: any;
    let merkleTree: any;
    let tokenName = "";
    let tokenSymbol = "";

    beforeEach(async function () {
      const setup = await setUpContract();
      contract = setup.contract;
      owner = setup.owner;
      whitelist = setup.whitelist;
      merkleTree = setup.merkleTree;
      tokenName = setup.tokenName;
      tokenSymbol = setup.tokenSymbol;
    });
    // 1.Le Deployer est bien le owner du contrat
    it("Deployer should be owner", async function () {
        expect(await contract.owner()).to.equal(owner.address);
    });
    // 2. Vérification du nom et du symbole du token
    it("Should have correct name and symbol", async function () {
        expect(await contract.name()).to.equal(tokenName);
        expect(await contract.symbol()).to.equal(tokenSymbol);
    });
  });
  describe("2. Minting and Ownership", function () {

    let contract: any;
    let owner: any;
    let whitelist: any;
    let merkleTree: any;
    let tokenName = "";
    let tokenSymbol = "";

    beforeEach(async function () {
      const setup = await setUpContract();
      contract = setup.contract;
      owner = setup.owner;
      whitelist = setup.whitelist;
      merkleTree = setup.merkleTree;
      tokenName = setup.tokenName;
      tokenSymbol = setup.tokenSymbol;
    });
    // 1. Vérification qu'un NFT est minté au déploiement
    it("Should have genesis NFT minted at deployment", async function () {
        const nextTokenId = await contract.totalSupply();
        expect(nextTokenId).to.equal(1n);
        const ownerOfGenesisNFT = await contract.ownerOf(0);
        expect(ownerOfGenesisNFT).to.equal(owner.address);
    });
    // 2. Vérification du mapping des adresses ayant minté un NFT
    it("Should track addresses that have minted NFTs", async function () {
        const hasMinted = await contract.hasAddressMinted(owner.address);
        console.log(`L'adresse ${owner.address} a minté un NFT : ${hasMinted}`);
        expect(hasMinted).to.be.true;

    });
    // 3. Retourne la liste des token IDs mintés par une adresse
    it("Should return list of token IDs minted by an address", async function () {
        const tokenIds = await contract.getTokenIDsByAddress(owner.address);
        console.log(`Token IDs mintés par l'adresse ${owner.address} : ${tokenIds}`);
        expect(tokenIds.length).to.equal(1);
        expect(tokenIds[0]).to.equal(0);
    });
    // 4. Vérification d'un mint par une adresse whitelisted
    it("Whitelisted address should be able to mint a NFT", async function () {
        const whitelistedAddress = whitelist[1]; 
        const proof = merkleTree.getProof([whitelistedAddress]);
        const uri = "bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmve";
        const mintTx = await contract.connect(ethers.getSigner(whitelistedAddress)).mintMindchainWithProof(uri, proof);
        await expect(mintTx)
            .to.emit(contract, "MindchainMinted")
            .withArgs(whitelistedAddress, 1, uri);
        const nextTokenId = await contract.totalSupply();
        expect(nextTokenId).to.equal(2n);
    });
  });

  describe.skip("2. Contract writing functions", function () {

    let contract: any;
    let owner: any;
    let user1: any;
    let user2: any;
    const uri = "bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmve";
        
    beforeEach(async function () {
      const setup = await setUpContractWithUser();
      contract = setup.contract;
      owner = setup.owner;
      user1 = setup.user1;
      user2 = setup.user2;
    });
    // 1. Un utilisateur peut minter un NFT
    it("Minting a NFT emits event and increases total supply by 1", async function () {
        // Récupération du totalSupply avant le mint
        const nextTokenIdBefore = await contract.totalSupply()
        // Calcul du totalSupply attendu après le mint
        const nextTokenIdExpected = (nextTokenIdBefore + 1n);
        // Mint d'un NFT pour l'utilisateur
        const mintTx = await contract.mintMindchain(
            user.address,
            uri
        );
        // Vérification de l'émission de l'événement Minted
        await expect(mintTx)
            .to.emit(contract, "MindchainMinted")
            .withArgs(user.address, nextTokenIdBefore, uri);
        // Vérification de l'augmentation du totalSupply
        const nextTokenId = await contract.totalSupply();
        expect(nextTokenId).to.equal(nextTokenIdExpected);
    });
    // 2. Ajouter une adresse à la whitelist par le owner
    it.skip("Owner can add address to whitelist", async function () {
        await contract.connect(owner).addAddressToWhitelist(user.address);
        const isWhitelisted = await contract.connect(owner).isAddressWhitelisted(user.address);
        expect(isWhitelisted).to.be.true;
    });
    // 3. Suppression d'une adresse de la whitelist par le owner
    it.skip("Owner can remove address from whitelist", async function () {
      const whitelisted = await ethers.getSigners();
      console.log(owner.address, whitelisted[0].address);
      // 1. Owner ajoute user à la whitelist
      await contract.connect(owner).addAddressToWhitelist(user.address);
      // 2. Owner supprime user de la whitelist
      await contract.connect(owner).removeAddressFromWhitelist(user.address);
      // 3. Vérification
      const isWhitelisted = await contract.isAddressWhitelisted(user.address);
      expect(isWhitelisted).to.equal(false);
        });
  });
});
