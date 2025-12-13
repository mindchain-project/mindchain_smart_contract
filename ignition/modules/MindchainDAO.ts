import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import whitelist  from "../../whitelist.json";

export default buildModule("MindchainDAOModule", (m) => {
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