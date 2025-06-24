// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IStakedAvax is IERC20 {
    function getSharesByPooledAvax(uint256 avaxAmount) external view returns (uint256);
    function getPooledAvaxByShares(uint256 shareAmount) external view returns (uint256);
    function submit() external payable returns (uint256);
}
