import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const DAO_addresses = [
        "0x9e7dd23be678960fd1a4873c35a87d1ee4f3d63e",
        "0xf5568ef10e21c5287690bd30925e1ea6979cfd28",
        "0xd827b1db5d72f76badfe66f5fe6f97550d2a0ef3",
        "0x0046049972de61280ed26d8850771923d5e08788"
    ]

export const DAOModule = buildModule("MindchainDAOModule", (m) => {
    // Récupération du compte deployer (le premier compte)
    const owner = m.getAccount(0);
    // Déploiement du contrat NFT avec le nom du contrat, le deployer et la racine de l'arbre de Merkle
    const daoContract = m.contract(
        "MindchainDAO", [owner]
    );
    // // Ajout des membres initiaux à la DAO
    // for (const address of DAO_addresses) {
    //     m.call(daoContract, "addMember", [address], { id: `AddMember_${address}` });
    // }
    return { daoContract };
});