import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import whitelist from "../contracts/whitelist.json";

// Extraction des adresses whitelisted
const DAO_addresses = whitelist.DAO_addresses;
// const DAO_addresses = [
//         "0x9e7dd23be678960fd1a4873c35a87d1ee4f3d63e",
//         "0xf5568ef10e21c5287690bd30925e1ea6979cfd28",
//         "0xd827b1db5d72f76badfe66f5fe6f97550d2a0ef3",
//         "0x0046049972de61280ed26d8850771923d5e08788"
//     ]

export const DAOModule = buildModule("MindchainDAOModule", (ignitionBuilder) => {
    // Récupération du compte deployer (le premier compte)
    const owner = ignitionBuilder.getAccount(0);
    // Déploiement du contrat NFT avec le nom du contrat, le deployer et la racine de l'arbre de Merkle
    const daoContract = ignitionBuilder.contract(
        "MindchainDAO", [owner, DAO_addresses]
    );
    // Retourne le contrat déployé avec la racine de l'arbre de Merkle de la whitelist
    return { daoContract };
});