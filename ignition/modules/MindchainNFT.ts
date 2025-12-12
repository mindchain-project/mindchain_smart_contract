import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { DAOModule } from "./MindchainDAO.js";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const DAO_addresses = [
        "0x9e7dd23be678960fd1a4873c35a87d1ee4f3d63e",
        "0xf5568ef10e21c5287690bd30925e1ea6979cfd28",
        "0xd827b1db5d72f76badfe66f5fe6f97550d2a0ef3",
        "0x0046049972de61280ed26d8850771923d5e08788"
    ]

export default buildModule("MindchainNFTModule", (m) => {
    // Build du module DAO pour récupérer la whitelist des admins
    // const { daoContract } = m.useModule(DAOModule);
    // console.log("Déploiement du module MindchainNFTModule", daoContract);
    // const daoMembers = DAO_addresses
    // const genesisURI = "bafkreig7bzqhsjksgys4kp4eceg5esg4ss6ddsqvb36uzeachfhmnvhiai";
    // const tokenName = "Mindchain";
    // const tokenSymbol = "MDC";
    // const merkleTree = StandardMerkleTree.of(daoContract.address, ["address"])
    // console.log(`Racine de l'arbre de Merkle pour le NFT : ${merkleTree.root}`);
    // // Déploiement du contrat NFT avec le nom du contrat, le deployer et la racine de l'arbre de Merkle
    // const nftContract = m.contract(
    //     "MindchainNFT",
    //     [daoContract, genesisURI, merkleTree.root, tokenName, tokenSymbol]
    // );
    // // Retourne le contrat déployé avec la racine de l'arbre de Merkle de la whitelist
    // return { nftContract };
});