import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { DAOModule } from "./MindchainDAO.js";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

import whitelist from "../contracts/whitelist.json";
const DAO_addresses = whitelist.DAO_addresses;

export default buildModule("MindchainNFTModule", (ignitionBuilder) => {
    // Build du module DAO pour récupérer la whitelist des admins
    const { daoContract } = ignitionBuilder.useModule(DAOModule);
    const daoMembers = DAO_addresses
    const genesisURI = "bafkreig7bzqhsjksgys4kp4eceg5esg4ss6ddsqvb36uzeachfhmnvhiai";
    const tokenName = "Mindchain";
    const tokenSymbol = "MDC";
    const merkleTree = StandardMerkleTree.of(daoContract.isMember(), ["address"])
    console.log(`Racine de l'arbre de Merkle pour le NFT : ${merkleTree.root}`);
    // Déploiement du contrat NFT avec le nom du contrat, le deployer et la racine de l'arbre de Merkle
    const nftContract = ignitionBuilder.contract(
        "MindchainNFT",
        [daoContract, genesisURI, merkleTree.root, tokenName, tokenSymbol]
    );
    // Retourne le contrat déployé avec la racine de l'arbre de Merkle de la whitelist
    return { nftContract };
});