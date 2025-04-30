// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./DecentralizedIdentityNFT.sol";
import "./DecentralizedFileSharing.sol";

/**
 * @title DecentralizedIdentityFactory
 * @dev Factory contract to deploy and manage the DID NFT and File Sharing contracts
 */
contract DecentralizedIdentityFactory is Ownable {
    DecentralizedIdentityNFT public didNFTContract;
    DecentralizedFileSharing public fileSharingContract;
    
    // Governance parameters
    uint256 public verifierCount;
    uint256 public minVerifiersRequired;
    mapping(address => bool) public isVerifier;
    mapping(string => mapping(address => bool)) public didVerifications;
    mapping(string => uint256) public verificationCount;
    
    // Events
    event VerifierAdded(address indexed verifier);
    event VerifierRemoved(address indexed verifier);
    event DIDVerificationRequested(string did, address indexed wallet);
    event DIDVerified(string did, address indexed wallet, uint256 verificationCount);
    
    constructor() Ownable() {

        // Deploy the NFT contract
        didNFTContract = new DecentralizedIdentityNFT();
        
        // Deploy the file sharing contract
        fileSharingContract = new DecentralizedFileSharing(address(didNFTContract));
        
        // Initialize governance parameters
        verifierCount = 1;
        minVerifiersRequired = 1;
        isVerifier[msg.sender] = true;
    }
    
    /**
     * @dev Add a DID verifier
     * @param verifier The address of the verifier to add
     */
    function addVerifier(address verifier) public onlyOwner {
        require(!isVerifier[verifier], "Already a verifier");
        isVerifier[verifier] = true;
        verifierCount++;
        emit VerifierAdded(verifier);
    }
    
    /**
     * @dev Remove a DID verifier
     * @param verifier The address of the verifier to remove
     */
    function removeVerifier(address verifier) public onlyOwner {
        require(isVerifier[verifier], "Not a verifier");
        require(verifier != owner(), "Cannot remove owner as verifier");
        isVerifier[verifier] = false;
        verifierCount--;
        emit VerifierRemoved(verifier);
    }
    
    /**
     * @dev Set the minimum number of verifiers required
     * @param count The new minimum count
     */
    function setMinVerifiersRequired(uint256 count) public onlyOwner {
        require(count > 0 && count <= verifierCount, "Invalid verifier count");
        minVerifiersRequired = count;
    }
    
    /**
     * @dev Register a DID for the caller
     * @param did The DID to register
     */
    function registerDID(string memory did) public {
        didNFTContract.registerDID(did);
        emit DIDVerificationRequested(did, msg.sender);
    }
    
    /**
     * @dev Verify a DID as a verifier
     * @param did The DID to verify
     * @param wallet The wallet associated with the DID
     */
    function verifyDID(string memory did, address wallet) public {
        require(isVerifier[msg.sender], "Not a verifier");
        require(keccak256(bytes(didNFTContract.getDID(wallet))) == keccak256(bytes(did)), "DID does not match wallet");
        
        // Make sure this verifier hasn't already verified this DID
        require(!didVerifications[did][msg.sender], "Already verified by this verifier");
        
        // Record the verification
        didVerifications[did][msg.sender] = true;
        verificationCount[did]++;
        
        // If we have enough verifications, mark the DID as verified in the NFT contract
        if (verificationCount[did] >= minVerifiersRequired) {
            didNFTContract.verifyDID(did, true);
        }
        
        emit DIDVerified(did, wallet, verificationCount[did]);
    }
    
    /**
     * @dev Mint a new NFT for a file
     * @param tokenURI The token URI (metadata)
     * @param encryptedContentHash The encrypted content hash (IPFS CID)
     * @return The new token ID
     */
    function mintFileNFT(
        string memory tokenURI,
        string memory encryptedContentHash
    ) public returns (uint256) {
        // Make sure the caller has a verified DID
        string memory did = didNFTContract.getDID(msg.sender);
        require(bytes(did).length > 0, "You must register a DID first");
        require(didNFTContract.isDIDVerified(did), "Your DID must be verified first");
        
        // Mint the NFT
        return didNFTContract.mintFileNFT(msg.sender, tokenURI, encryptedContentHash);
    }
    
    /**
     * @dev Register a new file in the system
     * @param encryptedKeyForOwner The encrypted file key for the owner
     * @param validUntil The timestamp until which this file is valid
     * @return The new file ID
     */
    function registerFile(
        string memory encryptedKeyForOwner,
        uint256 validUntil
    ) public returns (uint256) {
        return fileSharingContract.registerFile(encryptedKeyForOwner, validUntil);
    }
    
    /**
     * @dev Share a file with another wallet
     * @param fileId The ID of the file to share
     * @param recipient The recipient address
     * @param encryptedKeyForRecipient The encrypted file key for the recipient
     * @param validUntil The timestamp until which this share is valid
     * @param canEdit Whether the recipient can edit the file
     */
    function shareFile(
        uint256 fileId,
        address recipient,
        string memory encryptedKeyForRecipient,
        uint256 validUntil,
        bool canEdit
    ) public {
        fileSharingContract.shareFile(fileId, recipient, encryptedKeyForRecipient, validUntil, canEdit);
    }
    
    /**
     * @dev Get all files shared with a user
     * @param user The user to check
     * @return An array of file IDs
     */
    function getFilesSharedWithUser(address user) public view returns (uint256[] memory) {
        return fileSharingContract.getFilesSharedWithUser(user);
    }
}