// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "solady/src/tokens/ERC20.sol";
//import {IStakedAvax} from "../interfaces/IStakedAvax.sol";

contract MockStackedAvax is ERC20 {
    uint256 private _totalAvax;
    uint256 public constant DEPLOYED_AT = block.timestamp;

    mapping(address => bool) private _airdrop;
    event Airdrop(address indexed to, uint256 amount);


    // Override con especificación explícita para evitar ambigüedad
    function name() public pure override returns (string memory) {
        return "MOCK Staked AVAX";
    }

    function symbol() public pure override returns (string memory) {
        return "mSAVAX";
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalAvax() public view returns (uint256) {
        // dummy calculation to simulate total AVAX staked increase
        uint256 onePercentDaily = (block.timestamp - DEPLOYED_AT) * _totalAvax / 100 / 1 days;
        
        return _totalAvax + onePercentDaily;
    }

    function mintAirdrop(address to) external {
        uint256 amount = 10 ether;
        require(!_airdrop[to], "Airdrop already claimed");
        _airdrop[to] = true;
        _totalAvax += amount;
        _mint(to, totalSupply() * amount / totalAvax());
        emit Airdrop(to, amount);
    }

    function getPooledAvaxByShares(uint256 shareAmount) external view  returns (uint256) {
        return totalAvax() * shareAmount / totalSupply();
    }

    function getSharesByPooledAvax(uint256 avaxAmount) external view  returns (uint256) {
        return totalSupply() * avaxAmount / totalAvax();
    }

    function submit() external payable  returns (uint256) {
        _mint(msg.sender, msg.value);
        return msg.value;
    }
}
