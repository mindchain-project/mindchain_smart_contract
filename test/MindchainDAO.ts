import { expect, use } from "chai";
import { network } from "hardhat";
import { emit } from "process";

const { ethers } = await network.connect();

// Fonction de setup du déploiement du smart contract
async function setUpContract() {
  const [owner]  = await ethers.getSigners();
  const contract = await ethers.deployContract(
    "MindchainDAO", [ ]
  );
  await contract.waitForDeployment();
  return { contract, owner };
}
async function setUpContractWithMembers() {
    const { contract, owner } = await setUpContract();
    const [, ...signers] = await ethers.getSigners();
    const members = signers.slice(0, 4).map(signer => signer.address);
    return { contract, owner, members };
}


describe("Mindchain DAO Contract", function () {

    describe("1. Setup Contract", function () {
        let contract: any;
        let owner: any;
        let members: string[];
        beforeEach(async function () {
            const setup = await setUpContract();
            contract = setup.contract;
            owner = setup.owner;
            const [, ...signers] = await ethers.getSigners();
            members = signers.slice(0, 4).map(signer => signer.address);
        });
        // 1.Le owner du contrat est le deployer
        it("Deployer should be owner", async function () {
            expect(await contract.owner()).to.equal(owner.address);
        });
        // 2.Le premier membre est le deployer
        it("Deployer should be first member", async function () {
            expect(await contract.isMember(owner.address)).to.equal(true);
        });
    });

    describe("2. Members", function () {
        let contract: any;
        let owner: any;
        let members: string[];
        beforeEach(async function () {
            const setup = await setUpContract();
            contract = setup.contract;
            owner = setup.owner;
            const [, ...signers] = await ethers.getSigners();
            members = signers.slice(0, 4).map(signer => signer.address);
        });
        // 1. Vérification que les membres peuvent ajouter des membres
        it("Only member should add member", async function () {
            // Ajout d'un membre
            await expect(
                contract.connect(owner)
                .addMember(members[2])
            ).to.emit(contract, "MemberCountChanged")
            .withArgs(2, owner.address); // +1 pour le deployer
                        // Vérification que le membre a bien été ajouté
            expect(await contract.isMember(members[2])).to.equal(true);
        });
        // 2. Vérification qu'un non-membre ne peut pas ajouter de membre
        it("Non member should not add member", async function () {
            await expect(
                contract.connect(await ethers.getSigner(members[0]))
                .addMember(members[1])
            ).to.be.revertedWith("Caller is not a DAO member.");
        });
        // 3.Un membre ne peut pas ajouter un membre déjà existant
        it("Should not add existing member", async function () {
            await contract.connect(owner).addMember(members[2]);
            await expect(
                contract.connect(owner)
                .addMember(members[2])
            ).to.be.revertedWith("Already member");
        });
        // 4. Vérification que les membres peuvent supprimer des membres
        it("Only member should remove member", async function () {
            // Ajout d'un membre
            await contract.connect(owner).addMember(members[1]);
            await contract.connect(owner).addMember(members[2]);
            // Suppression du membre ajouté
            await expect(
                contract.connect(owner)
                .removeMember(members[1])
            ).to.emit(contract, "MemberCountChanged")
            .withArgs(2, owner.address); // Retour à 2
            // Vérification que le membre a bien été supprimé
            expect(await contract.isMember(members[1])).to.equal(false);
        });
        // 5. Vérification qu'un non-membre ne peut pas supprimer de membre
        it("Non member should not remove member", async function () {
            await expect(
                contract.connect(await ethers.getSigner(members[3]))
                .removeMember(members[2])
            ).to.be.revertedWith("Caller is not a DAO member.");
        });
        // 6.Un membre ne peut pas supprimer un membre inexistant ou si le nombre minimum de membres n'est pas respecté
        it("Should not remove non-existing member or below min members", async function () {
            // membre inexistant
            await expect(
                contract.connect(owner)
                .removeMember(members[1])
            ).to.be.revertedWith("Not a member");
            // le nombre minimum de membres n'est pas respecté
            await expect(
                contract.connect(owner)
                .removeMember(owner.address)
            ).to.be.revertedWith("Minimum members required");
        });
    });

    describe("3. Contracts", function () {
        let contract: any;
        let member: any;
        let nftContract: any;
        beforeEach(async function () {
            const setup = await setUpContract();
            contract = setup.contract;
            member = setup.owner;
            const nftContractFactory = await ethers.getContractFactory("MindchainNFT");
            nftContract = await nftContractFactory.deploy(
                member.address,
                "bafkreidvbhs33ighmljlvr7zbv2ywwzcmp5adtf4kqvlly67cy56bdtmve",
                "0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1",
                "Mindchain",
                "MDC"
            );
        });
        // 1. Enregistrement des contrats déployés
        it("Only member should register deployed contracts", async function () {
            
            // Enregistrement du contrat déployé par un membre
            await expect(
                contract.connect(member)
                .registerDeployedContract(nftContract.target)
            ).to.emit(contract, "NFTContractDeployed")
            .withArgs(nftContract.target, member.address);
            // Vérification que le contrat a bien été enregistré
            const deployedContracts = await contract.deployedContracts(0);
            expect(deployedContracts).to.equal(nftContract.target);
        });
        // 2. Tentative d'enregistrement par un non-membre
        it("Non member should not register deployed contracts", async function () {
            const [, signer] = await ethers.getSigners();
            await expect(
                contract.connect(signer)
                .registerDeployedContract(nftContract.target)
            ).to.be.revertedWith("Caller is not a DAO member.");
        });
    });
});