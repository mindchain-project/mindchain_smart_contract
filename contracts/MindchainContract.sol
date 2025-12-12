// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MindchainContract is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {


    // Balance du contrat
    uint256 public contractBalance;
    // Compteur pour l'ID des tokens
    uint256 private _nextNftTokenId;
    // Prix de mint par défaut pour un certificat
    uint256 public mintCertificationValue = 0.00004 * 1 ether;
    // Prix de mint de génération par défaut
    uint256 public generationValue = 0.0002 * 1 ether;
    // Mapping des adresses qui ont minté un certificat
    mapping(address => bool) private hasMintedCertification;
    // Mapping des adresses qui ont minté une génération
    mapping(address => bool) private hasGenerated;
    // Racine de l'arbre de Merkle pour les adresses administrateurs
    bytes32 public memberMerkleRoot;

    // Événement émis lors du mint d'un nouveau Mindchain NFT
    event CertificationMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string metadataCid
    );
    event CertificationBurned(
        address indexed owner,
        uint256 indexed tokenId
    );
    event GenerationPayed(
        address indexed payer,
        uint256 amount
    );
    event MemberlistModified(
        address indexed user,
        bool isMember
    );

    /// @notice Modificateur pour restreindre l'accès aux membres whitelistés.
    modifier onlyMember(bytes32[] calldata _proof) {
        require(isMember(msg.sender, _proof), "Caller is not an Member.");
        _;
    }


    /// @notice Constructeur pour initialiser le contrat Mindchain NFT.
    /// @param _initialOwner L'adresse du propriétaire initial du contrat.
    /// @param _genesisNftUri L'URI des métadonnées du NFT initial à minter.
    /// @param _merkleRoot La racine Merkle pour la validation des certificats.
    constructor(
        address _initialOwner, 
        string memory _genesisNftUri, 
        bytes32 _merkleRoot
    )
        ERC721("Mindchain", "MDN")
        Ownable(_initialOwner)
    {
        // Initialisation du merkle root
        memberMerkleRoot = _merkleRoot;
        // Mint un NFT initial par le contrat lui-même
        mintCertification(_genesisNftUri);
        emit CertificationMinted(address(this), 0, _genesisNftUri);

    }

    /// @notice Fonction pour recevoir des fonds.
    receive() external payable {
        contractBalance += msg.value;
    }
    /// @notice Fonction de fallback pour recevoir des fonds.
    fallback() external payable { 
        contractBalance += msg.value;
    }

    /// @notice Minte un nouveau Mindchain NFT avec les métadonnées fournies.
    /// @param _uri L'URI des métadonnées du token. => un fichier JSON stocké sur IPFS
    /// @return ID du token nouvellement minté.
    function mintCertification(string memory _uri) 
        public
        returns (uint256)
    {   // Incrémente l'ID du token
        uint256 _nftTokenId = _nextNftTokenId++;
        // Mint le token
        _safeMint(msg.sender, _nftTokenId);
        // Définit l'URI des métadonnées
        _setTokenURI(_nftTokenId, _uri);
        // Marque l'adresse comme ayant minté un certificat
        hasMintedCertification[msg.sender] = true;
        // Emet l'événement de mint
        emit CertificationMinted(msg.sender, _nftTokenId, _uri);
        return _nftTokenId;
    }

    /// @notice Minte une génération en payant le prix défini.
    /// @return true si le paiement est réussi.
    function mintGeneration()
        payable
        public 
        returns (bool) {   
        require(msg.value == generationValue, unicode"Fond insuffisant pour la génération");
        // Incrémente le balance du contrat
        contractBalance += msg.value;
        // Marque l'adresse comme ayant généré
        hasGenerated[msg.sender] = true;
        emit GenerationPayed(msg.sender, msg.value);
        return true;
    }

    function mintCertificationPayed(string memory _uri)
        payable
        public 
        returns (uint256) {   
        require(msg.value == mintCertificationValue, unicode"Fond insuffisant pour le mint du certificat");
        // Incrémente la balance du contrat
        contractBalance += msg.value;
        // Mint le certificat
        uint256 tokenId = mintCertification(_uri);
        return tokenId;
    }

    /// @notice Vérifie si une adresse a déjà minté un certificat.
    /// @param _address L'adresse à vérifier.
    /// @return true si l'adresse a minté, false sinon.
    function hasAddressMintedCertification(address _address) external view returns (bool) {
        return hasMintedCertification[_address];
    }
    /// @notice Vérifie si une adresse a déjà généré.
    /// @param _address L'adresse à vérifier.
    /// @return true si l'adresse a généré, false sinon.
    function hasAddressGenerated(address _address) external view returns (bool) {
        return hasGenerated[_address];
    }

    /// @notice Modifie le prix de mint des NFTs.
    /// @param _newPrice Le nouveau prix de mint.
    /// @param _proof La preuve Merkle pour valider l'administrateur.
    function setMintCertificationValue(uint256 _newPrice, bytes32[] calldata _proof) 
        external 
        onlyMember(_proof) {
        mintCertificationValue = _newPrice;
    }

    /// @notice Modifie la prix de génération.
    /// @param _newPrice Le nouveau prix.
    /// @param _proof La preuve Merkle pour valider l'administrateur.
    function setGenerationValue(uint256 _newPrice, bytes32[] calldata _proof) 
        external 
        onlyMember(_proof) {
        generationValue = _newPrice;
    }

    /// @notice Retire des fonds du contrat vers une adresse spécifiée.
    /// @param _to L'adresse vers laquelle les fonds seront envoyés.
    /// @param _amount Le montant des fonds à retirer.
    /// @param _proof La preuve Merkle pour valider l'administrateur.
    function withdrawValue(address payable _to, uint _amount, bytes32[] calldata _proof) 
        external 
        onlyMember(_proof) {
        // Pour éviter la faille de reentrancy
        uint currentBalance = address(this).balance;
        require(_amount <= currentBalance, "Balance insuffisante");
        _to.transfer(_amount);
        contractBalance = currentBalance - _amount;
    }

    /// @notice Supprime un Mindchain NFT en brûlant le token avec l'ID spécifié.
    /// @param _tokenId L'ID du token à brûler.
    function deleteCertificationToken(uint256 _tokenId)
        external {
        // Vérifie que l'appelant est le propriétaire du token
        require(msg.sender == ownerOf(_tokenId), "Not the token owner");
        burn(_tokenId);
        // Emet l'événement de burn
        emit CertificationBurned(msg.sender, _tokenId);
    }

    /// @notice Met à jour la racine Merkle pour la whitelist.
    /// @param _merkleRoot La nouvelle racine Merkle.
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        memberMerkleRoot = _merkleRoot;
    }

    /// @notice Vérifie si une adresse est dans la whitelist des membres.
    /// @param _account L'adresse à vérifier.
    /// @param _proof La preuve Merkle pour valider l'appartenance à la whitelist.
    /// @return true si l'adresse est dans la whitelist, false sinon.
    function isMember(address _account, bytes32[] calldata _proof) 
        internal 
        view 
        returns(bool) {
        // Calcul de la feuille de l'arbre (double hashage pour la sécurité contre Second Preimage Attack)
        bytes32 leaf = keccak256(abi.encode(keccak256(abi.encode(_account))));
        // Vérification de la preuve contre la racine
        return MerkleProof.verify(_proof, memberMerkleRoot, leaf);
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
