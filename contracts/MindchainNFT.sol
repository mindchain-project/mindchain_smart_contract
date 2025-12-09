// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.5.0
pragma solidity ^0.8.28;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MindchainNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {
    
    uint256 private _nextTokenId;

    event MindchainMinted(
        address indexed owner,
        uint256 indexed tokenId,
        string metadataCid
    );

    constructor(address _initialOwner)
        ERC721("Mindchain", "MDC")
        Ownable(_initialOwner)
    {}


    /// @notice Safely mints a new token with the given URI to the specified address.
    /// @dev Only the contract owner can call this function. => Mindchain is the owner
    /// @param _to The address to mint the token to.
    /// @param _uri The URI of the token metadata. => a JSON file stored on IPFS
    /// @return Token ID of the newly minted token.
    function mintMindchain(address _to, string memory _uri) 
        public
        payable
        returns (uint256)
    {   // Set the token ID to the next available ID
        uint256 _tokenId = _nextTokenId++;
        // Mint the token and set its URI
        _safeMint(_to, _tokenId);
        // Set the token URI
        _setTokenURI(_tokenId, _uri);
        // Emit event
        emit MindchainMinted(_to, _tokenId, _uri);
        // Return the new token ID
        return _tokenId;
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
