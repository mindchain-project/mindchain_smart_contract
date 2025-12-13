import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import whitelist  from "../../whitelist.json";
import { daoContract } from "./MindchainDAO";

export default buildModule("MindchainNFTModule", (m) => {
    // Build du module DAO pour récupérer la whitelist des admins
    console.log("Déploiement du module MindchainNFTModule", daoContract);
    const daoMembers = whitelist.members.map((address: string) => [address]);
    const genesisURI = "bafkreig7bzqhsjksgys4kp4eceg5esg4ss6ddsqvb36uzeachfhmnvhiai";
    const tokenName = "Mindchain";
    const tokenSymbol = "MDC";
    const merkleTree = StandardMerkleTree.of(daoContract.address, ["address"])
    console.log(`Racine de l'arbre de Merkle pour le NFT : ${merkleTree.root}`);
    // Déploiement du contrat NFT avec le nom du contrat, le deployer et la racine de l'arbre de Merkle
    const nftContract = m.contract(
        "MindchainNFT",
        [daoContract, genesisURI, merkleTree.root, tokenName, tokenSymbol]
    );
    // Retourne le contrat déployé avec la racine de l'arbre de Merkle de la whitelist
    return { nftContract };
});