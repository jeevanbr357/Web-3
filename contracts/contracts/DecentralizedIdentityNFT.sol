// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title DecentralizedIdentityNFT
 * @dev ERC721 token for decentralized identity with NFT functionality
 */
contract DecentralizedIdentityNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    // Mapping from wallet address to DID
    mapping(address => string) private _walletToDID;
    
    // Mapping from DID to verification status
    mapping(string => bool) private _didVerified;
    
    // Mapping from token ID to encrypted content hash
    mapping(uint256 => string) private _tokenToEncryptedHash;
    
    // Events
    event DIDRegistered(address indexed wallet, string did);
    event DIDVerified(string did, bool status);
    event FileNFTMinted(uint256 indexed tokenId, address indexed owner, string encryptedContentHash);
    
    constructor() ERC721("Decentralized Identity NFT", "DINFT") Ownable() {}

    
    /**
     * @dev Register a DID (Decentralized Identifier) for a wallet address
     * @param did The DID to register
     */
    function registerDID(string memory did) public {
        require(bytes(_walletToDID[msg.sender]).length == 0, "DID already registered for this wallet");
        _walletToDID[msg.sender] = did;
        emit DIDRegistered(msg.sender, did);
    }
    
    /**
     * @dev Get the DID for a wallet address
     * @param wallet The wallet address to query
     * @return The associated DID or empty string if not registered
     */
    function getDID(address wallet) public view returns (string memory) {
        return _walletToDID[wallet];
    }
    
    /**
     * @dev Update the verification status of a DID
     * @param did The DID to verify/unverify
     * @param status The verification status
     */
    function verifyDID(string memory did, bool status) public onlyOwner {
        _didVerified[did] = status;
        emit DIDVerified(did, status);
    }
    
    /**
     * @dev Check if a DID is verified
     * @param did The DID to check
     * @return Verification status
     */
    function isDIDVerified(string memory did) public view returns (bool) {
        return _didVerified[did];
    }
    
    /**
     * @dev Mint a new NFT representing a file
     * @param recipient The recipient of the NFT
     * @param tokenURI The metadata URI for the NFT
     * @param encryptedContentHash The encrypted content hash (IPFS CID)
     * @return The new token ID
     */
    function mintFileNFT(
        address recipient,
        string memory tokenURI,
        string memory encryptedContentHash
    ) public returns (uint256) {
        require(recipient != address(0), "Invalid recipient address");
        
        // Increment the token counter
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        // Mint the new token
        _mint(recipient, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        
        // Store the encrypted content hash
        _tokenToEncryptedHash[newTokenId] = encryptedContentHash;
        
        // Emit the event
        emit FileNFTMinted(newTokenId, recipient, encryptedContentHash);
        
        return newTokenId;
    }
    
    /**
     * @dev Get the encrypted content hash for a token
     * @param tokenId The token ID
     * @return The encrypted content hash
     */
    function getEncryptedContentHash(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return _tokenToEncryptedHash[tokenId];
    }
    
    /**
     * @dev Check if a token exists
     * @param tokenId The token ID to check
     * @return Whether the token exists
     */
    
    function _exists(uint256 tokenId) internal view override returns (bool) {
    return super._exists(tokenId);
}

}