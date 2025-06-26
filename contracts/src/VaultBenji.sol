// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "solady/src/auth/Ownable.sol";
import {IStakedAvax} from "./interfaces/IStakedAvax.sol";

contract Vault is Ownable {
    uint256 private totalBalance; // in avax
    IStakedAvax private sAVAX;
    address public raffle;

    constructor(address _sAVAX) {
        sAVAX = IStakedAvax(_sAVAX);
        _initializeOwner(msg.sender);
    }

    function deposit() external payable {
        require(msg.sender == raffle, "ONLY_RAFFLE");
        require(msg.value > 0, "NO_ZERO_AMOUNT");
        totalBalance += msg.value;

        // Deposit AVAX into sAVAX
        sAVAX.submit{value: msg.value}();
    }

    function depositSAVAX(uint256 amount) external {
        require(msg.sender == raffle, "ONLY_RAFFLE");
        require(amount > 0, "NO_ZERO_AMOUNT");
        sAVAX.transferFrom(msg.sender, address(this), amount);
        totalBalance += sAVAX.getPooledAvaxByShares(amount);
    }

    function withdraw(address to, uint256 amount) external {
        require(msg.sender == raffle, "ONLY_RAFFLE");
        require(amount > 0, "NO_ZERO_AMOUNT");

        totalBalance -= amount;

        // Withdraw AVAX from sAVAX
        sAVAX.transfer(to, sAVAX.getSharesByPooledAvax(amount));
    }

    function withdrawToWinner(address winner) external {
        require(msg.sender == raffle, "ONLY_RAFFLE");
        uint256 amount = totalPrice();
        if (amount == 0) return;
        uint256 sAVAXamount = sAVAX.getSharesByPooledAvax(amount);
        sAVAX.transfer(winner, sAVAXamount);
    }

    function totalPrice() public view returns (uint256) {
        uint256 totalPlusRebase = sAVAX.getPooledAvaxByShares(sAVAX.balanceOf(address(this)));
        if (totalBalance > totalPlusRebase) {
            return 0;
        }
        return totalPlusRebase - totalBalance;
    }

    function setRaffle(address _raffle) external onlyOwner {
        require(_raffle != address(0), "NO_ZERO_ADDRESS");
        raffle = _raffle;
    }

    // @warning: this function is used to withdraw stuck tokens from the vault, its a centralization
    // risk, good for now but probably should be removed in the future
    function withdrawStuck(address _token, uint256 amount) external onlyOwner {
        require(_token != address(0), "NO_ZERO_ADDRESS");
        require(amount > 0, "NO_ZERO_AMOUNT");

        (bool success,) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, amount));
        require(success, "TRANSFER_FAILED");
    }
}
