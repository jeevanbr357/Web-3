// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DecentralizedIdentityNFT.sol";

/**
 * @title DecentralizedFileSharing
 * @dev Implements secure file sharing functionality with DID-based access control
 */
contract DecentralizedFileSharing is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _fileIds;
    
    DecentralizedIdentityNFT private _didNFTContract;
    
    struct FileAccess {
        address owner;
        string encryptedKeyForOwner;
        uint256 validUntil; // 0 means no expiration
        bool isActive;
    }
    
    struct FileShare {
        address sharedBy;
        address sharedTo;
        string encryptedKeyForRecipient;
        uint256 validUntil; // 0 means no expiration
        bool canEdit;
        bool isActive;
    }
    
    // Mapping from file ID to file access info
    mapping(uint256 => FileAccess) private _fileAccess;
    
    // Mapping from file ID to shared access (address => FileShare)
    mapping(uint256 => mapping(address => FileShare)) private _fileShares;
    
    // Mapping from wallet to files shared with them
    mapping(address => uint256[]) private _sharedWithWallet;
    
    // Events
    event FileRegistered(uint256 indexed fileId, address indexed owner, uint256 validUntil);
    event FileShared(uint256 indexed fileId, address indexed sharedBy, address indexed sharedTo, uint256 validUntil, bool canEdit);
    event FileAccessRevoked(uint256 indexed fileId, address indexed revokedFrom);
    event FileDeleted(uint256 indexed fileId);
    
   constructor(address didNFTContractAddress) Ownable() {

        _didNFTContract = DecentralizedIdentityNFT(didNFTContractAddress);
    }
    
    /**
     * @dev Register a new file in the system with encrypted access key
     * @param encryptedKeyForOwner The encrypted file key that only the owner can decrypt
     * @param validUntil The timestamp until which this file is valid (0 for no expiration)
     * @return The new file ID
     */
    function registerFile(
        string memory encryptedKeyForOwner,
        uint256 validUntil
    ) public returns (uint256) {
        // Make sure the caller has a registered DID
        require(bytes(_didNFTContract.getDID(msg.sender)).length > 0, "You must register a DID first");
        
        // Increment the file counter
        _fileIds.increment();
        uint256 newFileId = _fileIds.current();
        
        // Create the file access info
        _fileAccess[newFileId] = FileAccess({
            owner: msg.sender,
            encryptedKeyForOwner: encryptedKeyForOwner,
            validUntil: validUntil,
            isActive: true
        });
        
        // Emit the event
        emit FileRegistered(newFileId, msg.sender, validUntil);
        
        return newFileId;
    }
    
    /**
     * @dev Share a file with another wallet
     * @param fileId The ID of the file to share
     * @param recipient The recipient address
     * @param encryptedKeyForRecipient The encrypted file key that only the recipient can decrypt
     * @param validUntil The timestamp until which this share is valid (0 for no expiration)
     * @param canEdit Whether the recipient can edit the file
     */
    function shareFile(
        uint256 fileId,
        address recipient,
        string memory encryptedKeyForRecipient,
        uint256 validUntil,
        bool canEdit
    ) public {
        // Make sure the file exists and the caller is the owner
        require(_fileAccess[fileId].isActive, "File does not exist or is inactive");
        require(_fileAccess[fileId].owner == msg.sender, "Only the file owner can share it");
        
        // Make sure the recipient has a registered DID
        require(bytes(_didNFTContract.getDID(recipient)).length > 0, "Recipient does not have a registered DID");
        
        // Create the file share
        _fileShares[fileId][recipient] = FileShare({
            sharedBy: msg.sender,
            sharedTo: recipient,
            encryptedKeyForRecipient: encryptedKeyForRecipient,
            validUntil: validUntil,
            canEdit: canEdit,
            isActive: true
        });
        
        // Add this file to the recipient's shared list
        _sharedWithWallet[recipient].push(fileId);
        
        // Emit the event
        emit FileShared(fileId, msg.sender, recipient, validUntil, canEdit);
    }
    
    /**
     * @dev Revoke a file share
     * @param fileId The ID of the file
     * @param recipient The recipient whose access to revoke
     */
    function revokeFileShare(uint256 fileId, address recipient) public {
        // Make sure the file exists and the caller is the owner
        require(_fileAccess[fileId].isActive, "File does not exist or is inactive");
        require(_fileAccess[fileId].owner == msg.sender, "Only the file owner can revoke sharing");
        
        // Make sure there is an active share for this recipient
        require(_fileShares[fileId][recipient].isActive, "No active share for this recipient");
        
        // Deactivate the share
        _fileShares[fileId][recipient].isActive = false;
        
        // Emit the event
        emit FileAccessRevoked(fileId, recipient);
    }
    
    /**
     * @dev Delete a file (deactivate it)
     * @param fileId The ID of the file to delete
     */
    function deleteFile(uint256 fileId) public {
        // Make sure the file exists and the caller is the owner
        require(_fileAccess[fileId].isActive, "File does not exist or is inactive");
        require(_fileAccess[fileId].owner == msg.sender, "Only the file owner can delete it");
        
        // Deactivate the file
        _fileAccess[fileId].isActive = false;
        
        // Emit the event
        emit FileDeleted(fileId);
    }
    
    /**
     * @dev Check if a user has access to a file
     * @param fileId The ID of the file
     * @param user The user to check
     * @return A tuple of (hasAccess, canEdit, encryptedKey)
     */
    function checkFileAccess(uint256 fileId, address user) public view returns (bool, bool, string memory) {
        // If the user is the owner, they have full access
        if (_fileAccess[fileId].owner == user && _fileAccess[fileId].isActive) {
            // Check if the file has expired
            if (_fileAccess[fileId].validUntil == 0 || _fileAccess[fileId].validUntil > block.timestamp) {
                return (true, true, _fileAccess[fileId].encryptedKeyForOwner);
            }
        }
        
        // Check if the user has shared access
        FileShare memory share = _fileShares[fileId][user];
        if (share.isActive) {
            // Check if the share has expired
            if (share.validUntil == 0 || share.validUntil > block.timestamp) {
                return (true, share.canEdit, share.encryptedKeyForRecipient);
            }
        }
        
        // No access
        return (false, false, "");
    }
    
    /**
     * @dev Get all files shared with a user
     * @param user The user to check
     * @return An array of file IDs
     */
    function getFilesSharedWithUser(address user) public view returns (uint256[] memory) {
        return _sharedWithWallet[user];
    }
    
    /**
     * @dev Get file details
     * @param fileId The ID of the file
     * @return owner The file owner
     * @return validUntil The file validity
     * @return isActive Whether the file is active
     */
    function getFileDetails(uint256 fileId) public view returns (
        address owner,
        uint256 validUntil,
        bool isActive
    ) {
        FileAccess memory access = _fileAccess[fileId];
        return (
            access.owner,
            access.validUntil,
            access.isActive
        );
    }
}