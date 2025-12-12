import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import whitelist  from "../../whitelist.json";

export default buildModule("MindchainContractModule", (m) => {
    const members = whitelist.members.map((address: string) => [address]);
    console.log("Membres:", members);
    const genesisUri = "bafybeidpcbs5gklqwqgb22hsmb5vlyv242lvttlpenmapb72fxjrnsawde";
    const merkleTree = StandardMerkleTree.of(members, ["address"]);
    console.log(`Racine de l'arbre de Merkle : ${merkleTree.root}`);

    // Récupération du compte deployer (le premier compte)
    const owner = m.getAccount(0);
    // Déploiement du contrat NFT avec le nom du contrat, le deployer et la racine de l'arbre de Merkle
    const mindchainContract = m.contract(
        "MindchainContract", [owner, genesisUri, merkleTree.root]
    );
    return { mindchainContract };
});