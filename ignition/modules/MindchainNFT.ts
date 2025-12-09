import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MindchainNFTModule", (ignitionBuilder) => {
    // Récupération du compte deployer (le premier compte)
    const owner = ignitionBuilder.getAccount(0);
    // Déploiement du contrat NFT avec le nom du contrat, le deployer et la racine de l'arbre de Merkle
    const nftContract = ignitionBuilder.contract(
        "MindchainNFT", [owner]
    );
    // Retourne le contrat déployé avec la racine de l'arbre de Merkle de la whitelist
    return { nftContract };
});