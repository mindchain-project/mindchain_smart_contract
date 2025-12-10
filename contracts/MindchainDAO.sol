// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/// @title Contrat Mindchain DAO pour la gestion des membres et le déploiement de contrats NFT.
contract MindchainDAO is Ownable {

    // Mapping pour suivre le status des membres
    mapping(address => bool) public isMember;
    // Nombre total de membres
    uint public membersCount;
    // Nombre minimum de membres actifs requis
    uint private constant MIN_MEMBERS = 2;
    // Liste des contrats déployés par le DAO
    address[] public deployedContracts;

    event MemberCountChanged(
        uint indexed newMemberCount,
        address indexed changedBy
    );
    event NFTContractDeployed(
        address indexed nftContractAddress,
        address indexed deployedBy
    );  

    /// @notice Modificateur pour restreindre l'accès aux fonctions aux seuls membres du DAO.
    modifier onlyMember() {
        require(isMember[msg.sender], "Caller is not a DAO member.");
        _;
    }

    /// @notice Constructeur pour initialiser le contrat Mindchain DAO.
    constructor() Ownable(msg.sender) {
        // Le deployer devient le premier membre
        isMember[msg.sender] = true;
        membersCount = 1;
    }

    /// @notice Vérifie si une adresse est membre du DAO.
    /// @param _address L'adresse à vérifier.
    function isMemberAddress(address _address) external view returns (bool) {
        return isMember[_address];
    }

    /// @notice Ajoute un nouveau membre au DAO.
    /// @param _newMember L'adresse du nouveau membre à ajouter.
    function addMember(address _newMember) external onlyMember {
        require(!isMember[_newMember], "Already member");
        isMember[_newMember] = true;
        membersCount++;
        emit MemberCountChanged(membersCount, msg.sender);
    }

    /// @notice Supprime un membre du DAO.
    /// @param _member L'adresse du membre à supprimer.
    function removeMember(address _member) external onlyMember {
        require(isMember[_member], "Not a member");
        require(membersCount > MIN_MEMBERS, "Minimum members required");
        isMember[_member] = false;
        membersCount--;
        emit MemberCountChanged(membersCount, msg.sender);
    }

    /// @notice Enregistre un contrat NFT déployé par le DAO.
    /// @param _nftContractAddress L'adresse du contrat NFT déployé.
    function registerDeployedContract(address _nftContractAddress) external onlyMember {
        deployedContracts.push(_nftContractAddress);
        emit NFTContractDeployed(_nftContractAddress, msg.sender);
    }
}