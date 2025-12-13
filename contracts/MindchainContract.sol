// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract MindchainContract is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, IERC721Receiver, Ownable {


    // Balance du contrat
    uint256 private contractBalance;

    // Compteur pour l'ID des tokens
    uint256 public nextNftTokenId;
    // Prix de mint par défaut pour un certificat
    uint256 public mintCertificationValue = 4 * 10**13 wei;
    // Mapping des adresses ayant déjà minté un certificat
    mapping(address => bool) private hasMintedCertification;

    // Prix de mint de génération par défaut
    uint256 public generationValue = 2 * 10**13 wei;
    // Mapping des adresses ayant déjà généré
    mapping(address => bool) private hasGenerated;

    // Compteur de credit de générations par adresse
    mapping(address => AddressBalance) private addressBalances;
   
    // Racine de l'arbre de Merkle pour les adresses membres
    bytes32 private memberMerkleRoot;

    struct AddressBalance {
        uint256 generation;
        uint256 certification;
    }

    enum ServiceStudio {
        CERTIFICATION,
        GENERATION
    }

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
    event AddressBalanceUpdated(
        address indexed payer,
        uint256 amount,
        string _reason,
        string service
    );
    event WhitelistModified(
        address indexed user,
        bool isMember
    );
    event GenerationCreditAvailable(
        address indexed payer,
        uint256 creditAmount
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
        mintCertification(address(this), _genesisNftUri);
        emit CertificationMinted(address(this), 0, _genesisNftUri);

    }

    /* ------------- Fonctions getter et setter ------------- */

    /// @notice Récupère la balance du contrat.
    /// @return La balance du contrat en wei.
    function getContractBalance() external view returns (uint256) {
        return contractBalance;
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

    /// @notice Modifie le prix de mint de certification.
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

    /// @notice Récupère la balance d'une adresse spécifique.
    /// @param _address L'adresse dont la balance est demandée.
    /// @return La structure AddressBalance contenant les crédits de génération et de certification.
    function getAddressBalance(address _address) 
        external 
        view 
        returns (AddressBalance memory) {
        return addressBalances[_address];
    }

    /// @notice Récupère la racine Merkle utilisée pour la validation des membres.
    /// @return La racine Merkle.
    function getMerkleRoot() external view returns (bytes32) {
        return memberMerkleRoot;
    }
    
    /// @notice Met à jour la racine Merkle pour la whitelist.
    /// @param _merkleRoot La nouvelle racine Merkle.
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        memberMerkleRoot = _merkleRoot;
    }

    /* ------------- Fonctions de réception de fonds ------------- */

    /// @notice Fonction pour recevoir des fonds.
    receive() external payable {
        contractBalance += msg.value;
    }
    /// @notice Fonction de fallback pour recevoir des fonds.
    fallback() external payable { 
        contractBalance += msg.value;
    }

    /* ------------- Fonctions principales du contrat ------------- */

    /// @notice Minte un nouveau Mindchain NFT avec les métadonnées fournies.
    /// @param _to L'adresse du propriétaire du nouveau NFT.
    /// @param _uri L'URI des métadonnées du token. => un fichier JSON stocké sur IPFS
    function mintCertification(address _to, string memory _uri) 
        public {   
        // Incrémente l'ID du token
        uint256 tokenId = nextNftTokenId++;
        // Mint le token
        _safeMint(_to, tokenId);
        // Définit l'URI des métadonnées
        _setTokenURI(tokenId, _uri);
        // Marque l'adresse comme ayant minté un certificat
        hasMintedCertification[_to] = true;
        // Emet l'événement de mint
        emit CertificationMinted(_to, tokenId, _uri);
    }

    /// @notice Utilise le service de génération par une adresse spécifiée.
    /// @param _to L'adresse qui utilise le service de génération.
    function useGenerationService(address _to) 
        public
        virtual {
        // Pour l'instant, rien à faire pour la génération
        hasGenerated[_to] = true;
        uint availableCredit = addressBalances[_to].generation;
        emit GenerationCreditAvailable(_to, availableCredit);
    }

    /// @notice Utilise le crédit de l'utilisateur pour mint un certificat via un service studio.
    /// @param _to L'adresse qui utilise le service studio.
    /// @param _uri L'URI des métadonnées du token.
    /// @param _serviceStudioIndex Le service studio demandé.
    function useStudioWithCredit(address _to, string memory _uri, uint _serviceStudioIndex)
        payable
        public {
        // Montant reçu
        uint256 receivedAmount = msg.value;
        // Vérifie que le service studio est valide
        if (_serviceStudioIndex > uint(ServiceStudio.GENERATION)) {
            revert("Service studio inconnu");
        }
        // Paramètres du studio
        uint256 requiredCredit ;
        string memory serviceStudioName;
        if (_serviceStudioIndex == uint(ServiceStudio.CERTIFICATION)) {
            serviceStudioName = "CERTIFICATION";
            requiredCredit = mintCertificationValue;
        } else if (_serviceStudioIndex == uint(ServiceStudio.GENERATION)) {
            serviceStudioName = "GENERATION";
            requiredCredit = generationValue;
        }
        // Vérifie que l'utilisateur a envoyé suffisamment de fonds
        require(receivedAmount >= requiredCredit, unicode"Fond insuffisant pour ce service");
        // Met à jour la balance du contrat
        contractBalance += receivedAmount;
        // Met à jour le crédit pour l'adresse
        _handleBalanceUpdate(
            _to,
            receivedAmount,
            serviceStudioName,
            "CREDIT"
        );
        emit AddressBalanceUpdated(_to, receivedAmount, "CREDIT", serviceStudioName);
        if (_serviceStudioIndex == uint(ServiceStudio.CERTIFICATION)) {
            // Mint du certificat
            mintCertification(_to, _uri);
        } else if (_serviceStudioIndex == uint(ServiceStudio.GENERATION)) {
            useGenerationService(_to);
        }
        _handleBalanceUpdate(
            _to,
            requiredCredit,
            serviceStudioName,
            "DEBIT"
        );
        emit AddressBalanceUpdated(_to, requiredCredit, "DEBIT",serviceStudioName);
        // Effectue le service studio demandé
       
    }

    /// @notice Gère la mise à jour des balances par adresse.
    /// @param _payer L'adresse dont la balance doit être mise à jour.
    /// @param _amount Le montant à créditer ou débiter.
    /// @param _service Le service concerné (CERTIFICATION ou GENERATION).
    /// @param _reason La raison de la mise à jour (CREDIT ou DEBIT).
    function _handleBalanceUpdate(address _payer, uint256 _amount, string memory _service, string memory _reason)
        internal {
        // Mise à jour de la balance en fonction de la raison
        if (keccak256(bytes(_reason)) == keccak256("CREDIT") && keccak256(bytes(_service)) == keccak256("CERTIFICATION")) {
            AddressBalance memory balance = addressBalances[_payer];
            balance.certification += _amount;
            addressBalances[_payer] = balance;
        } else if (keccak256(bytes(_reason)) == keccak256("DEBIT") && keccak256(bytes(_service)) == keccak256("CERTIFICATION")) {
            // Utilisation du crédit de certification
            AddressBalance memory balance = addressBalances[_payer];
            require(balance.certification >= _amount, unicode"Crédit de certification insuffisant");
            balance.certification -= _amount;
            addressBalances[_payer] = balance;
        } else if (keccak256(bytes(_reason)) == keccak256("CREDIT") && keccak256(bytes(_service)) == keccak256("GENERATION")) {
            AddressBalance memory balance = addressBalances[_payer];
            balance.generation += _amount;
            addressBalances[_payer] = balance;
        } else if (keccak256(bytes(_reason)) == keccak256("DEBIT") && keccak256(bytes(_service)) == keccak256("GENERATION")) {
            // Utilisation du crédit de génération
            AddressBalance memory balance = addressBalances[_payer];
            require(balance.generation >= _amount, unicode"Crédit de génération insuffisant");
            balance.generation -= _amount;
            addressBalances[_payer] = balance;
        }
    }

    /* ------------- Fonctions administratives ------------- */

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

    /// @notice Supprime un NFT en brûlant le token avec l'ID spécifié.
    /// @param _tokenId L'ID du token à brûler.
    function deleteCertificationToken(uint256 _tokenId)
        external {
        // Vérifie que l'appelant est le propriétaire du token
        require(msg.sender == ownerOf(_tokenId), "Not the token owner");
        burn(_tokenId);
        // Emet l'événement de burn
        emit CertificationBurned(msg.sender, _tokenId);
    }

    /// @notice Vérifie si une adresse est dans la whitelist des membres.
    /// @param _account L'adresse à vérifier.
    /// @param _proof La preuve Merkle pour valider l'appartenance à la whitelist.
    /// @return true si l'adresse est dans la whitelist, false sinon.
    function isMember(address _account, bytes32[] calldata _proof) 
        public 
        view 
        returns(bool) {
        // Calcul de la feuille de l'arbre (double hashage pour la sécurité contre Second Preimage Attack)
        bytes32 leaf = keccak256(abi.encode(keccak256(abi.encode(_account))));
        // Vérification de la preuve contre la racine
        return MerkleProof.verify(_proof, memberMerkleRoot, leaf);
    }


    /// @notice Gère la réception de NFTs ERC721.
    /// @return Le sélecteur de la fonction onERC721Received.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /// @notice Transfère un NFT détenu par le contrat à une adresse spécifiée.
    /// @param to L'adresse destinataire du NFT.
    function transferFromContract(
        address to,
        uint256 tokenId
    ) external onlyOwner {
        _safeTransfer(address(this), to, tokenId, "");
    }


    /* ------------- Overrides requis par Solidity ------------- */
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
