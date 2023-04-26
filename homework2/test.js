
const { ethers } = require("hardhat");
const {
  Contract,
} = require("hardhat/internal/hardhat-network/stack-traces/model");
require("dotenv").config();

async function main() {
  const contractAddress = "0xd9e94f20309E3105552Ff62EE587092E87EdB42d";
  const abi = require("../artifacts/contracts/MultiSigWallet.sol/MultiSigWallet.json").abi;

  const provider = new ethers.providers.JsonRpcProvider("https://eth-sepolia.g.alchemy.com/v2/Ih9x2c6cYiXkQqF4rpDrOCUkdgtmzgWs");
  const signer = new ethers.Wallet(process.env.PK, provider);

  const multiSigWallet = new ethers.Contract(contractAddress, abi, signer);

  const owners = await multiSigWallet.getOwners();
  console.log("Owners:", owners);

  const requiredConfirmations = await multiSigWallet.getRequiredConfirmations();
  console.log("Required confirmations:", requiredConfirmations);

  const to = "0x1111111111111111111111111111111111111111";
  const value = ethers.utils.parseEther("1.0");

  const createTransactionTx = await multiSigWallet.createTransaction(to, value);
  console.log("Transaction created, tx hash:", createTransactionTx.hash);

  const transactionsCount = await multiSigWallet.getTransactionsCount();
  console.log("Transactions count:", transactionsCount.toNumber());

  const transaction = await multiSigWallet.transactions(transactionsCount - 1);
  console.log("Last transaction:", transaction);

  const confirmTransactionTx = await multiSigWallet.confirmTransaction(transactionsCount - 1);
  console.log("Transaction confirmed, tx hash:", confirmTransactionTx.hash);

  const executeTransactionTx = await multiSigWallet.executeTransaction(transactionsCount - 1);
  console.log("Transaction executed, tx hash:", executeTransactionTx.hash);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
