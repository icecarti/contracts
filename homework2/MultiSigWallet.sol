// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;
    uint public requiredConfirmations;
    mapping (uint => Transaction) public transactions;
    uint public transactionsCount = 0;
    
    struct Transaction {
        address to;
        uint value;
        bool executed;
        mapping (address => bool) confirmations;
    }
    
    modifier onlyOwners() {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
            }
        }
        require(isOwner, "Sender is not an owner");
        _;
    }
    
    
    modifier NotExecuted(uint transactionId) {
        require(!transactions[transactionId].executed, "Transaction has been executed");
        _;
    }
    
    modifier Confirmed(uint transactionId) {
        require(transactions[transactionId].confirmations[msg.sender], "Transaction has not been confirmed by sender");
        _;
    }
    
    modifier NotConfirmed(uint transactionId) {
        require(!transactions[transactionId].confirmations[msg.sender], "Transaction has been confirmed by sender");
        _;
    }
    
    modifier ValidRequirement(uint ownerCount, uint _requiredConfirmations) {
        require(ownerCount > 0, "Owner count must be greater than 0");
        require(_requiredConfirmations > 0 && _requiredConfirmations <= ownerCount, "Required confirmations must be greater than 0 and less than or equal to owner count");
        _;
    }
    
    constructor(address[] memory _owners, uint _requiredConfirmations) ValidRequirement(_owners.length, _requiredConfirmations) {
        for (uint i = 0; i < _owners.length; i++) {
            owners.push(_owners[i]);
        }
        requiredConfirmations = _requiredConfirmations;
    }
    
    function createTransaction(address _to, uint _value) public onlyOwners {
        transactions[transactionsCount].to = _to;
        transactions[transactionsCount].value = _value;
        transactions[transactionsCount].executed = false;
        transactionsCount++;
    }
    
    function confirmTransaction(uint _transactionId) public onlyOwners NotExecuted(_transactionId) NotConfirmed(_transactionId) {
        transactions[_transactionId].confirmations[msg.sender] = true;
    }
    
    function executeTransaction(uint _transactionId) public onlyOwners NotExecuted(_transactionId) Confirmed(_transactionId){
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (transactions[_transactionId].confirmations[owners[i]] == true) {
                count++;
            }
        }
        require(count >= requiredConfirmations, "Transaction requires more confirmations");
        (bool success, ) = payable(transactions[_transactionId].to).call{value: transactions[_transactionId].value}("");
        require(success,"Something wrong");
        transactions[_transactionId].executed = true;
    }

    fallback() external payable {}

    receive() external payable {}
}
