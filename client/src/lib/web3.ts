import { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import { createDID, DecentralizedID } from './did';
import { 
  DecentralizedIdentityFactoryABI, 
  DecentralizedIdentityNFTABI,
  DecentralizedFileSharingABI 
} from './contracts/contractAbi';
import { 
  getContractAddress, 
  getNetworkInfo,
  LOCAL_HARDHAT_CHAIN_ID
} from './contracts/contractAddresses';

// Define the type for connected wallet
export interface ConnectedWallet {
  address: string;
  provider: ethers.BrowserProvider;
  signer: ethers.JsonRpcSigner;
  chainId: number;
  network: string;
  did: DecentralizedID;  // Added DID for decentralized identity
  walletType: 'exodus' | 'other';  // Track which wallet is connected
}

// Check if the wallet is Exodus
export function isExodusWallet(): boolean {
  // Check if it's a web browser environment
  if (typeof window === 'undefined') return false;
  
  // Exodus wallet can be detected in different ways:
  // 1. Check for window.exodus directly
  // 2. Check if the ethereum provider includes "exodus" in its name or properties
  
  // @ts-ignore - exodus is not in the window type
  if (window.exodus) return true;
  
  // Alternative detection: check if provider name or properties indicate Exodus
  if (window.ethereum) {
    try {
      // @ts-ignore - ethereum is not in the window type
      const providerInfo = window.ethereum.isExodus || 
        // @ts-ignore - ethereum is not in the window type
        (window.ethereum.isMetaMask === true && window.ethereum._metamask?.isExodus === true) ||
        // @ts-ignore - ethereum is not in the window type
        window.ethereum.providers?.some(p => p.isExodus);
      
      if (providerInfo) return true;
        
      // Last resort: check the user agent for Exodus
      if (navigator && navigator.userAgent && 
          navigator.userAgent.toLowerCase().includes('exodus')) {
        return true;
      }
    } catch (error) {
      console.warn('Error detecting wallet type:', error);
    }
  }
  
  // For demo purposes, let's assume it's Exodus when in development environment
  if (import.meta.env.DEV) {
    console.info('Development environment detected. Treating wallet as Exodus for demo purposes.');
    return true;
  }
  
  return false;
}

// Get the provider from browser
export async function getProvider(): Promise<ethers.BrowserProvider | null> {
  if (typeof window === 'undefined') {
    console.error('Not in browser environment');
    return null;
  }
  
  // Check for an injected Ethereum provider
  if (!window.ethereum) {
    console.error('No Web3 wallet detected. Please install Exodus or another Web3 wallet.');
    return null;
  }
  
  // Check for Exodus wallet
  const isExodus = isExodusWallet();
  
  try {
    // @ts-ignore - exodus is not in the window type
    if (isExodus && window.exodus && window.exodus.ethereum) {
      // Direct access to Exodus provider if available
      console.log('Using Exodus wallet provider directly');
      // @ts-ignore - exodus is not in the window type
      return new ethers.BrowserProvider(window.exodus.ethereum);
    }
    
    // Otherwise use the standard ethereum provider
    // In development, we'll treat it as if it's Exodus (via the isExodusWallet function)
    console.log('Using standard ethereum provider' + (isExodus ? ' (detected as Exodus)' : ''));
    return new ethers.BrowserProvider(window.ethereum);
    
  } catch (error) {
    console.error('Failed to get provider:', error);
    return null;
  }
}

// Create a mock wallet for development environments without web3 support
const createMockWallet = async (): Promise<ConnectedWallet> => {
  console.log('Creating mock wallet for development...');
  
  // Create a mock address
  const address = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";
  
  // Create a mock DID
  const did = createDID(address);
  
  // Create a minimal mock provider
  const mockProvider = {
    getNetwork: async () => ({ chainId: BigInt(1) }),
    getSigner: async () => ({
      getAddress: async () => address,
      signMessage: async (message: string) => `0x${"0".repeat(130)}` // Fake signature
    }),
    send: async (method: string, params: any[]) => {
      if (method === "eth_requestAccounts") return [address];
      return null;
    }
  } as unknown as ethers.BrowserProvider;
  
  // Create a mock signer
  const mockSigner = {
    getAddress: async () => address,
    signMessage: async (message: string) => `0x${"0".repeat(130)}`, // Fake signature
    connect: () => mockSigner
  } as unknown as ethers.JsonRpcSigner;
  
  return {
    address,
    provider: mockProvider,
    signer: mockSigner,
    chainId: 1,
    network: "Ethereum Mainnet (Demo)",
    did,
    walletType: 'exodus'
  };
};

// Connect to wallet
export async function connectWallet(): Promise<ConnectedWallet | null> {
  try {
    // For development environment without a web3 wallet
    if (import.meta.env.DEV && typeof window !== 'undefined' && !window.ethereum) {
      console.log('No Web3 wallet detected, using mock wallet for development');
      return await createMockWallet();
    }
    
    const provider = await getProvider();
    if (!provider) {
      if (import.meta.env.DEV) {
        console.log('Provider not available, using mock wallet for development');
        return await createMockWallet();
      }
      return null;
    }

    // Request account access
    const accounts = await provider.send("eth_requestAccounts", []);
    if (!accounts || accounts.length === 0) return null;
    
    const address = accounts[0];
    const signer = await provider.getSigner();
    const network = await provider.getNetwork();
    const chainId = network.chainId;
    
    // Create a DID for the user
    const did = createDID(address);
    
    // Determine wallet type
    const walletType = isExodusWallet() ? 'exodus' : 'other';
    
    // If not using Exodus wallet, show a warning
    if (walletType !== 'exodus') {
      console.warn('This application is designed to work with Exodus wallet for optimal security and identity management.');
    }
    
    // Determine network name
    let networkName;
    switch (Number(chainId)) {
      case 1:
        networkName = "Ethereum Mainnet";
        break;
      case 5:
        networkName = "Goerli Testnet";
        break;
      case 137:
        networkName = "Polygon Mainnet";
        break;
      case 80001:
        networkName = "Mumbai Testnet";
        break;
      case 42161:
        networkName = "Arbitrum One";
        break;
      case 10:
        networkName = "Optimism";
        break;
      default:
        networkName = "Unknown Network";
    }

    return {
      address,
      provider,
      signer,
      chainId: Number(chainId),
      network: networkName,
      did,
      walletType
    };
  } catch (error) {
    console.error('Failed to connect wallet:', error);
    
    // In development, provide a mock wallet on error
    if (import.meta.env.DEV) {
      console.log('Error connecting to wallet, using mock wallet for development');
      return await createMockWallet();
    }
    
    return null;
  }
}

// Mint NFT function using our DecentralizedIdentityFactory contract
export async function mintNFT(
  tokenURI: string,
  encryptedContentHash: string,
  wallet: ConnectedWallet
): Promise<ethers.TransactionReceipt | null> {
  try {
    // Get the factory contract address for the current network
    const factoryAddress = getContractAddress('DecentralizedIdentityFactory', wallet.chainId);
    
    // Create contract instance
    const factoryContract = new ethers.Contract(
      factoryAddress,
      DecentralizedIdentityFactoryABI,
      wallet.signer
    );

    // Call the mintFileNFT function on the factory contract
    const tx = await factoryContract.mintFileNFT(tokenURI, encryptedContentHash);
    return await tx.wait();
  } catch (error) {
    console.error('Failed to mint NFT:', error);
    return null;
  }
}

// Register a DID with the contract
export async function registerDID(
  wallet: ConnectedWallet
): Promise<ethers.TransactionReceipt | null> {
  try {
    // Get the factory contract address for the current network
    const factoryAddress = getContractAddress('DecentralizedIdentityFactory', wallet.chainId);
    
    // Create contract instance
    const factoryContract = new ethers.Contract(
      factoryAddress,
      DecentralizedIdentityFactoryABI,
      wallet.signer
    );

    // Call the registerDID function with the user's DID
    const tx = await factoryContract.registerDID(wallet.did.did);
    return await tx.wait();
  } catch (error) {
    console.error('Failed to register DID:', error);
    return null;
  }
}

// Register a file in the system with encrypted access key
export async function registerFile(
  encryptedKeyForOwner: string,
  validUntil: number, // Unix timestamp for expiration (0 = no expiration)
  wallet: ConnectedWallet
): Promise<{fileId: number, receipt: ethers.TransactionReceipt} | null> {
  try {
    // Get the factory contract address for the current network
    const factoryAddress = getContractAddress('DecentralizedIdentityFactory', wallet.chainId);
    
    // Create contract instance
    const factoryContract = new ethers.Contract(
      factoryAddress,
      DecentralizedIdentityFactoryABI,
      wallet.signer
    );

    // Call the registerFile function
    const tx = await factoryContract.registerFile(encryptedKeyForOwner, validUntil);
    const receipt = await tx.wait();
    
    // Extract the file ID from the event logs
    // The FileRegistered event emits fileId as the first indexed parameter
    const eventSignature = "FileRegistered(uint256,address,uint256)";
    const eventTopic = ethers.keccak256(ethers.toUtf8Bytes(eventSignature));
    
    const log = receipt.logs.find(log => log.topics[0] === eventTopic);
    if (!log) {
      console.error('Could not find FileRegistered event in transaction logs');
      return null;
    }
    
    // Parse the fileId from the event
    const fileId = Number(BigInt(log.topics[1]));
    
    return { fileId, receipt };
  } catch (error) {
    console.error('Failed to register file:', error);
    return null;
  }
}

// Share a file with another wallet
export async function shareFile(
  fileId: number,
  recipientAddress: string,
  encryptedKeyForRecipient: string,
  validUntil: number, // Unix timestamp for expiration (0 = no expiration)
  canEdit: boolean,
  wallet: ConnectedWallet
): Promise<ethers.TransactionReceipt | null> {
  try {
    // Get the factory contract address for the current network
    const factoryAddress = getContractAddress('DecentralizedIdentityFactory', wallet.chainId);
    
    // Create contract instance
    const factoryContract = new ethers.Contract(
      factoryAddress,
      DecentralizedIdentityFactoryABI,
      wallet.signer
    );

    // Call the shareFile function
    const tx = await factoryContract.shareFile(
      fileId,
      recipientAddress,
      encryptedKeyForRecipient,
      validUntil,
      canEdit
    );
    return await tx.wait();
  } catch (error) {
    console.error('Failed to share file:', error);
    return null;
  }
}

// Get files shared with a user
export async function getFilesSharedWithUser(
  wallet: ConnectedWallet
): Promise<number[] | null> {
  try {
    // Get the factory contract address for the current network
    const factoryAddress = getContractAddress('DecentralizedIdentityFactory', wallet.chainId);
    
    // Create contract instance
    const factoryContract = new ethers.Contract(
      factoryAddress,
      DecentralizedIdentityFactoryABI,
      wallet.provider // Use provider for read-only operations
    );

    // Call the getFilesSharedWithUser function
    return await factoryContract.getFilesSharedWithUser(wallet.address);
  } catch (error) {
    console.error('Failed to get shared files:', error);
    return null;
  }
}

// Hook for wallet connection
export function useWallet() {
  const [wallet, setWallet] = useState<ConnectedWallet | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Connect wallet
  const connect = async () => {
    try {
      setLoading(true);
      setError(null);
      const connectedWallet = await connectWallet();
      setWallet(connectedWallet);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to connect wallet');
    } finally {
      setLoading(false);
    }
  };

  // Disconnect wallet
  const disconnect = () => {
    setWallet(null);
  };

  // Listen for account changes - but only if ethereum provider exists
  useEffect(() => {
    // Skip this in environments without a wallet
    if (typeof window === 'undefined' || !window.ethereum) return;

    const handleAccountsChanged = (accounts: string[]) => {
      if (accounts.length === 0) {
        // User disconnected their wallet
        setWallet(null);
      } else if (wallet && accounts[0] !== wallet.address) {
        // Different account selected, reconnect
        connect();
      }
    };

    const handleChainChanged = () => {
      // Chain changed, refresh the page as recommended by MetaMask
      window.location.reload();
    };

    try {
      window.ethereum.on('accountsChanged', handleAccountsChanged);
      window.ethereum.on('chainChanged', handleChainChanged);

      return () => {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
        window.ethereum.removeListener('chainChanged', handleChainChanged);
      };
    } catch (error) {
      console.warn('Error setting up wallet event listeners:', error);
      return () => {}; // Empty cleanup if setup failed
    }
  }, [wallet]);

  return { wallet, loading, error, connect, disconnect };
}
