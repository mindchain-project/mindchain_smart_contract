// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Interface pour le contrat Mindchain DAO
interface IMindchainDAO {
    /// @notice Vérifie si une adresse est membre du DAO.
    /// @param _address L'adresse à vérifier.
    function isMember(address _address) external view returns (bool);
}

contract MindchainNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {

    // Référence au contrat DAO pour la gestion des membres
    IMindchainDAO public mindchainDAO;
    // Balance du contrat
    uint256 public contractBalance;
    // Compteur pour l'ID des tokens
    uint256 private _nextNftTokenId;
    // Prix de mint par défaut
    uint256 public mintPrice = 0.01 ether;
    // Mapping des adresses qui ont minté
    mapping(address => bool) private hasMinted;
    // Racine de l'arbre de Merkle pour les adresses qui ont mint
    bytes32 public merkleRoot;

    // Événement émis lors du mint d'un nouveau Mindchain NFT
    event MindchainMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string metadataCid
    );
    event MindchainBurned(
        address indexed owner,
        uint256 indexed tokenId
    );
    event Event(string message);

    /// @notice Constructeur pour initialiser le contrat Mindchain NFT.
    /// @param _initialOwner L'adresse du propriétaire initial du contrat.
    /// @param _genesisNftUri L'URI des métadonnées du NFT initial à minter.
    /// @param _merkleRoot La racine Merkle pour la validation des certificats.
    /// @param tokenName Le nom du token ERC721.
    /// @param tokenSymbol Le symbole du token ERC721.
    constructor(
        address _initialOwner, 
        string memory _genesisNftUri, 
        bytes32 _merkleRoot,
        string memory tokenName,
        string memory tokenSymbol
    )
        ERC721(tokenName, tokenSymbol)
        Ownable(_initialOwner)
    {
        // Initialisation des variables
        mindchainDAO = IMindchainDAO(_initialOwner);
        merkleRoot = _merkleRoot;
        // Mint un NFT initial au propriétaire du contrat
        mintMindchainNFT(_initialOwner, _genesisNftUri);
        emit MindchainMinted(_initialOwner, 0, _genesisNftUri);

    }

    /// @notice Fonction pour recevoir des fonds.
    receive() external payable {
        contractBalance += msg.value;
    }

    /// @notice Minte un nouveau Mindchain NFT à l'adresse spécifiée avec les métadonnées fournies.
    /// @param _to L'adresse à laquelle le token sera minté.
    /// @param _uri L'URI des métadonnées du token. => un fichier JSON stocké sur IPFS
    /// @return ID du token nouvellement minté.
    function mintMindchainNFT(address _to, string memory _uri) 
        public
        returns (uint256)
    {   // Incrémente l'ID du token
        uint256 _nftTokenId = _nextNftTokenId++;
        // Mint le token
        _safeMint(_to, _nftTokenId);
        // Définit l'URI des métadonnées
        _setTokenURI(_nftTokenId, _uri);
        // Approuve le propriétaire pour gérer le token
        // _setApprovalForAll(_to, owner, true);
        // Emet l'événement de mint
        emit MindchainMinted(_to, _nftTokenId, _uri);
        // Retourne l'ID du token minté
        return _nftTokenId;
    }

    /// @notice Modifie le prix de mint des NFTs.
    /// @param _newPrice Le nouveau prix de mint.
    function setMintPrice(uint256 _newPrice) external onlyOwner {
        mintPrice = _newPrice;
    }

    /// @notice Retire des fonds du contrat vers une adresse spécifiée.
    /// @param _to L'adresse vers laquelle les fonds seront envoyés.
    /// @param _amount Le montant des fonds à retirer.
    function withdrawValue(address payable _to, uint _amount) external {
        // Pour éviter la faille de reentrancy
        uint value = _amount;
        require(mindchainDAO.isMember(msg.sender), "Not a DAO member");
        require(value <= address(this).balance, "Insufficient balance");
        _to.transfer(value);
    }

    /// @notice Retourne un tableau des IDs de tokens possédés par une adresse donnée.
    /// @param _address L'adresse pour laquelle interroger les IDs de tokens possédés.
    /// @return Un tableau des IDs de tokens possédés par l'adresse spécifiée.
    function getTokenIDsByAddress(address _address)
        external
        view
        returns (uint256[] memory)
    {
        uint256 _tokenCount = balanceOf(_address);
        uint256[] memory tokenIds = new uint256[](_tokenCount);
        for (uint256 i = 0; i < _tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokenIds;
    }

    /// @notice Supprime un Mindchain NFT en brûlant le token avec l'ID spécifié.
    /// @param _tokenId L'ID du token à brûler.
    function deleteMindchainNFT(uint256 _tokenId)
        external
    {
        // Vérifie que l'appelant est le propriétaire du token
        require(msg.sender == ownerOf(_tokenId), "Not the token owner");
        burn(_tokenId);
        // Emet l'événement de burn
        emit MindchainBurned(msg.sender, _tokenId);
    }


    // To prevent compilation errors due to multiple inheritance, we need to override the following functions:
    /// @inheritdoc ERC721
    function _update(address _to, uint256 _tokenId, address _auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(_to, _tokenId, _auth);
    }
    /// @inheritdoc ERC721
    function _increaseBalance(address _account, uint128 _value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(_account, _value);
    }
    /// @inheritdoc ERC721URIStorage
    function tokenURI(uint256 _tokenId)
        public
        view
        override(ERC721URIStorage, ERC721)
        returns (string memory)
    {
        return super.tokenURI(_tokenId);
    }
    /// @inheritdoc ERC721
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }
}
