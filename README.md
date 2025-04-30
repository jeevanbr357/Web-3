# Identity storage DApp

A decentralized application for secure, on-chain file storage and sharing using **IPFS**, **Algorand (PyTeal)**, and **NFT-based ownership tracking**. It integrates decentralized identity (DID) and smart contract-based access control for robust privacy and security.

---

## About the Project

**Secure File Vault DApp** is a decentralized application designed for secure, private, and verifiable file sharing using blockchain and IPFS technology.

### Core Objectives

- **Decentralization**: Eliminate centralized control over personal or sensitive documents.
- **Security**: Protect shared files using encryption and decentralized identity (DID) based access control.
- **Transparency**: Smart contracts log and enforce file access and permissions on-chain.
- **Ownership**: Users retain full ownership and control over their data and files.

---

### Key Features

- File Upload to **IPFS** via **Pinata**
- DID-based user identity and access control
- Secure file sharing through **Algorand smart contracts** (PyTeal)
- NFT minting of files as proof of ownership
- Wallet-based login (MetaMask, Pera, Exodus)
- User-friendly frontend built with **React**


---

### Tech Stack

| Layer        | Technologies Used                             |
|--------------|------------------------------------------------|
| **Frontend** | React, Web3.js, Tailwind, WalletConnect        |
| **Backend**  | Node.js, REST API       |
| **Blockchain** | Algorand Smart Contracts written in PyTeal   |
| **Storage**  | IPFS (via Pinata)                              |
| **Authentication** | Wallet login + DID verification          |

![ChatGPT Image Apr 30, 2025, 05_01_58 PM](https://github.com/user-attachments/assets/00476b89-23b5-4190-b2db-7a18357e3213)




---


### Use Cases

- **Private File Sharing** – Share legal, academic, or sensitive documents securely.
- **Decentralized Certification** – Issue verified credentials or digital certificates.
- **DAO Access Control** – Restrict file access to community or organization members.
- **Web3 File Marketplace** – Sell or license digital assets using NFTs and smart contracts.

---

![image](https://github.com/user-attachments/assets/f8e3a553-d964-40b1-a038-8b7fd2652ba7)

## What You'll Learn

By working on or studying this project, you’ll gain hands-on experience with:

### Blockchain & Smart Contracts
- Writing smart contracts using **PyTeal** (Algorand's smart contract language)
- Deploying contracts to **Algorand MainNet** and interacting with them via clients
- Handling access control using decentralized logic

### Decentralized File Storage
- Uploading files to **IPFS** using **Pinata**
- Managing and retrieving IPFS CIDs securely

### Decentralized Identity (DID)
- Implementing DID-based user registration
- Associating DIDs with wallet addresses using smart contracts

### Full Stack Web3 Development
- Building a frontend in **React** with Web3 wallet integrations (MetaMask, Pera)
- Managing state, routes, and blockchain transactions in the UI
- Integrating with a backend using **Supabase** (PostgreSQL + RESTful APIs)

### Authentication & Authorization
- Wallet-based authentication flow using MetaMask and Algorand wallets
- Using smart contracts to control file sharing and access

### Web3 Ecosystem Tools
- Working with tools like **Algo-Builder**, **algokit**, **Web3.js**, and **React Query**
- Interfacing with blockchain explorers and MainNet APIs

---

This project is ideal for developers looking to explore the full spectrum of decentralized application (DApp) development — from storage and identity to contract deployment and UI integration.

---
## Useful Links

Here are some helpful resources for using, developing, or understanding this project:

### Algorand Blockchain
- [Algorand Developer Portal](https://developer.algorand.org/)
- [Algorand MainNet Explorer](https://algoexplorer.io)
- [Algorand TestNet Explorer](https://testnet.algoexplorer.io)
- [Algonode MainNet API](https://mainnet-api.algonode.cloud)

### Decentralized Storage (IPFS)
- [Pinata Cloud](https://www.pinata.cloud/)
- [IPFS Docs](https://docs.ipfs.tech/)

### Wallets
- [Pera Wallet](https://perawallet.app)
- [Exodus Wallet (Algorand Support)](https://www.exodus.com/download/)
- [MyAlgo Wallet (deprecated, but historically relevant)](https://wallet.myalgo.com)

### Dev Tools
- [AlgoKit CLI](https://github.com/algorandfoundation/algokit-cli)
- [Algo Builder](https://github.com/scale-it/algo-builder)
- [React](https://reactjs.org/)

### Other Resources
- [MIT License](https://opensource.org/licenses/MIT)
- [Web3.js Docs](https://web3js.readthedocs.io/)
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)



###  Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/secure-file-vault.git
cd secure-file-vault

# Install frontend dependencies
cd frontend
npm install
