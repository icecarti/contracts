// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Wallet is Ownable, ERC20 {
    uint feePercentETH = 0.01 ether;
    address commissionAdr = address(0);
    address thisAdr = address(this);
    mapping(address => mapping(address => uint)) allowances;
    mapping(address => uint) balances;
    mapping(address => uint) balancesOfTokens;
    event TransferMoney(address indexed from, address indexed to, uint amount);
    event ChangeFee(address indexed changer, uint amountFee);

    constructor() {}


    function changeFee(uint _fee) public onlyOwner() {
        feePercentETH = _fee;
        emit ChangeFee(_msgSender(),  _fee);
    }

    function trasnferTokens(address tokenAdr, uint amount) public payable {
        IERC20 token = IERC20(tokenAdr);
        uint allowanceAmount = token.allowance(_msgSender(), thisAdr);
        require(allowanceAmount >= amount , "Increase allowance");
        require(token.balanceOf(_msgSender()) > 0, "Buy tokens");
        require(token.transferFrom(_msgSender(), payable(thisAdr), amount), "Transaction failed");
        balancesOfTokens[_msgSender()] += amount;
        emit TransferMoney(_msgSender(), thisAdr, amount);

    }

    function withdrawTokens(address tokenAdr, uint amount) public {
        IERC20 token = IERC20(tokenAdr);
        require(balancesOfTokens[_msgSender()] >= amount, "Decrease amount");
        require(token.transfer(payable(_msgSender()), amount), "Transaction failed");
        balancesOfTokens[_msgSender()] -= amount;
        emit TransferMoney(thisAdr, _msgSender(), amount);
    }

    function transferETH(uint amount) public payable{
        require(amount >= 0, "Not enough funds");
        (bool success, ) = payable(thisAdr).call{value: amount}("");
        require(success, "Transaction failed");
        (bool successCommission, ) = payable(commissionAdr).call{value: feePercentETH}("");
        require(successCommission, "Fee transaction failed");
        balances[_msgSender()] += amount;
        emit TransferMoney(_msgSender(), thisAdr, amount);
    }

    function withdrawETH(uint amount) public {
        require(balances[_msgSender()] >= amount + feePercentETH, "Decrease amount");
        (bool success, ) = payable(_msgSender()).call{value: amount}("");
        require(success, "Transaction failed");
        (bool successCommission, ) = payable(commissionAdr).call{value: feePercentETH}("");
        require(successCommission, "Fee transaction failed");
        balances[_msgSender()] -= amount + feePercentETH;
        emit TransferMoney(thisAdr, _msgSender(), amount);
    }

    function allowanceOfTokens(address tokenAdr) public view returns(uint) {
        IERC20 token = IERC20(tokenAdr);
        return token.allowance(_msgSender(), thisAdr);
    }

    function approveTokens(address tokenAdr, uint amount) public onlyOwner() {
        IERC20 token = IERC20(tokenAdr);
        token.approve(thisAdr, amount);
    }

    fallback() external payable {
        emit TransferMoney(_msgSender(), thisAdr, msg.value);
    }

    receive() external payable {
        emit TransferMoney(_msgSender(), thisAdr, msg.value);
    }
}