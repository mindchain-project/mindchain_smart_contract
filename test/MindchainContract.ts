import { expect, use } from "chai";
import { network } from "hardhat";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const { ethers } = await network.connect();

// Fonction de setup du déploiement du smart contract
async function setUpContract() {
    // création des signers
    const signers = await ethers.getSigners();
    // le deployer est le premier signer
    const owner = signers[0];
    // création de la whitelist avec les 5 premiers signers
    const whitelist = signers.slice(0, 5).map(signer => signer.address);
    // URI du token genesis
    const uri = "bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmve";
    // création de l'arbre de Merkle à partir de la whitelist
    const merkleTree = StandardMerkleTree.of(
        whitelist.map(address => [address]),
        ["address"]
    );
    const root = merkleTree.root;
    // Déploiement du contrat MindchainNFT
    const contract = await ethers.deployContract(
        "MindchainContract", 
        [ owner.address, uri, root]
    );
    await contract.waitForDeployment();
    return { contract, owner, whitelist, merkleTree};
}


describe("Mindchain Contract", function () {
    // PARTIE I : Tests sur le déploiement du contrat
    describe("1. Contract setup", function () {
        // Variables communes à tous les tests
        let contract: any;
        let owner: any;
        let merkleTree: any;
        // Avant chaque test, on déploie un nouveau contrat
        beforeEach(async function () {
            const setup = await setUpContract();
            contract = setup.contract;
            owner = setup.owner;
            merkleTree = setup.merkleTree;
        });
        // 1.Le Deployer est bien le owner du contrat
        it("Deployer should be owner", async function () {
            expect(await contract.owner()).to.equal(owner.address);
        });
        // 2. Vérification du root de l'arbre de Merkle
        it("Should have correct Merkle root", async function () {
            expect(await contract.getMerkleRoot()).to.equal(merkleTree.root);
        });
        // 3. Le owner est dans la whitelist
        it("Owner should be in the member whitelist", async function () {
            const proof = merkleTree.getProof([owner.address]);
            const isInWhitelist = await contract.isMember(owner.address, proof);
            expect(isInWhitelist).to.be.true;
        });
        // 4. Vérification du mint du token genesis
        it("Should have genesis token minted at deployment", async function () {
            // Incrementation du totalSupply
            const nextTokenId = await contract.totalSupply();
            expect(nextTokenId).to.equal(1n);
            // Propriétaire et URI du token genesis
            const ownerOfGenesisToken = await contract.ownerOf(0);
            expect(ownerOfGenesisToken).to.equal(contract.address);
            // URI du token genesis
            const genesisTokenURI = await contract.tokenURI(0);
            expect(genesisTokenURI).to.equal("bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmve");
        });
        // 5. La balance du owner est de 1 (le token genesis)
        it("Owner should have balance of 1 (genesis token) and has minted certification", async function () {
            // Balance du owner
            const ownerBalance = await contract.balanceOf(owner.address);
            expect(ownerBalance).to.equal(1n);
            // Vérification du mapping des adresses ayant minté un NFT
            const ownerHasMinted = await contract.hasAddressMintedCertification(owner.address);
            expect(ownerHasMinted).to.be.true;
        });
        // 6. Vérification du nom et du symbole du token
        it("Should have correct token name and symbol", async function () {
            const tokenName = await contract.name();
            const tokenSymbol = await contract.symbol();
            expect(tokenName).to.equal("Mindchain");
            expect(tokenSymbol).to.equal("MDN");
        });
        // 7. Vérification des valeurs initiales de génération et de certification
        it("Should have correct initial values for generation and certification", async function () {
            const certificationValue = await contract.mintCertificationValue();
            expect(certificationValue).to.equal(4n * 10n ** 13n); // 0.00004 ETH en wei
            const generationValue = await contract.generationValue();
            expect(generationValue).to.equal(2n * 10n ** 13n); // 0.0002 ETH en wei
        });
        // 8. Vérification des balances initiales des adresses
        it("Should have correct initial address balances", async function () {
            const ownerBalance = await contract.getAddressBalance(owner.address);
            expect(ownerBalance.certification).to.equal(0n);
            expect(ownerBalance.generation).to.equal(0n);
        });

    });
    // PARTIE II : Tests sur les fonctions principales du contrat
    describe.only("2. Main contract functions", function () {
        // Variables communes à tous les tests
        let contract: any;
        let owner: any;
        let members: any;
        let merkleTree: any;
        let signerRandom: any;
        let signerMember: any;
        // Avant chaque test, on déploie un nouveau contrat
        beforeEach(async function () {
            const setup = await setUpContract();
            contract = setup.contract;
            owner = setup.owner;
            members = setup.whitelist;
            merkleTree = setup.merkleTree;
            signerMember = await ethers.getSigner(members[1]);
            [signerRandom] = (await ethers.getSigners()).slice(-1);
        });
        // 1. Vérification qu'un NFT est minté correctement
        it("Signer should mint a NFT", async function () {
            const tokenCountBefore = await contract.totalSupply();
            // Mint d'un NFT pour le signer
            const uri = "bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmve";
            const tokenId: bigint = await contract.mintCertification(
                signerRandom.address,
                uri
            );
            const tokenCountAfter = await contract.totalSupply();
            // Le function mintCertification retourne le tokenId minté
            expect(tokenId).to.equal(2n);
            console.log("Token ID minté:", (tokenId as any).value.toString());
            console.log("Token count before:", tokenCountBefore.toString());
            console.log("Token count after:", tokenCountAfter.toString());
            // Incrémentation du totalSupply
            expect(tokenCountAfter).to.equal(tokenCountBefore + 1n);
            // Émission de l'événement CertificationMinted
            await expect(tokenId)
                .to.emit(contract, "CertificationMinted")
                .withArgs(signerRandom.address, tokenCountAfter - 1n, uri);
            // Propriétaire du token minté
            const ownerOfMintedToken = await contract.ownerOf(tokenCountAfter - 1n);
            expect(ownerOfMintedToken).to.equal(signerRandom.address);
            // URI du token minté
            const mintedTokenURI = await contract.tokenURI(tokenCountAfter - 1n);
            expect(mintedTokenURI).to.equal(uri);
            // Balance du signer après le mint
            const signerBalance = await contract.balanceOf(signerRandom.address);
            expect(signerBalance).to.equal(1n);
            // Vérification du mapping des adresses ayant minté un NFT
            const hasMinted = await contract.hasAddressMintedCertification(signerRandom.address);
            expect(hasMinted).to.be.true;
        });
        // 2. Vérification qu'un signer peut supprimer son NFT
        it("Only NFT owner should burn their NFT", async function () {
            // Mint d'un NFT pour le signer
            const uri = "bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmie";
            const tokenId = await contract.mintCertification(
                signerRandom.address,
                uri
            );
            await tokenId.wait();
            console.log("Token ID minté:", (tokenId as any).value.toString());
            // Burn du NFT par le signer
            const burnTx = await contract.connect(signerRandom.address).deleteCertificationToken(tokenId);
            await expect(burnTx)
                .to.emit(contract, "CertificationBurned")
                .withArgs(signerRandom.address, tokenId);
            // Vérification que le NFT n'existe plus
            await expect(contract.ownerOf(tokenId)).to.be.revertedWith("ERC721: invalid token ID");
        });
    });
    // PARTIE III : Tests sur les fonctions d'administration du contrat
    describe("2. Contract writing functions", function () {
        // Variables communes à tous les tests
        let contract: any;
        let owner: any;
        let whitelist: any;
        let merkleTree: any;
        // Avant chaque test, on déploie un nouveau contrat
        beforeEach(async function () {
            const setup = await setUpContract();
            contract = setup.contract;
            owner = setup.owner;
            whitelist = setup.whitelist;
            merkleTree = setup.merkleTree;
        });
    //     // 1. Un utilisateur peut minter un NFT
    //     it("Minting a NFT emits event and increases total supply by 1", async function () {
    //         // Récupération du totalSupply avant le mint
    //         const nextTokenIdBefore = await contract.totalSupply()
    //         // Calcul du totalSupply attendu après le mint
    //         const nextTokenIdExpected = (nextTokenIdBefore + 1n);
    //         // Mint d'un NFT pour l'utilisateur
    //         const mintTx = await contract.mintMindchain(
    //             user.address,
    //             uri
    //         );
    //         // Vérification de l'émission de l'événement Minted
    //         await expect(mintTx)
    //             .to.emit(contract, "MindchainMinted")
    //             .withArgs(user.address, nextTokenIdBefore, uri);
    //         // Vérification de l'augmentation du totalSupply
    //         const nextTokenId = await contract.totalSupply();
    //         expect(nextTokenId).to.equal(nextTokenIdExpected);
    //     });
    //     // 2. Ajouter une adresse à la whitelist par le owner
    //     it.skip("Owner can add address to whitelist", async function () {
    //         await contract.connect(owner).addAddressToWhitelist(user.address);
    //         const isWhitelisted = await contract.connect(owner).isAddressWhitelisted(user.address);
    //         expect(isWhitelisted).to.be.true;
    //     });
    //     // 3. Suppression d'une adresse de la whitelist par le owner
    //     it.skip("Owner can remove address from whitelist", async function () {
    //     const whitelisted = await ethers.getSigners();
    //     console.log(owner.address, whitelisted[0].address);
    //     // 1. Owner ajoute user à la whitelist
    //     await contract.connect(owner).addAddressToWhitelist(user.address);
    //     // 2. Owner supprime user de la whitelist
    //     await contract.connect(owner).removeAddressFromWhitelist(user.address);
    //     // 3. Vérification
    //     const isWhitelisted = await contract.isAddressWhitelisted(user.address);
    //     expect(isWhitelisted).to.equal(false);
    //         });
    });
});
