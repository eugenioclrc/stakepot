// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

interface IStakedAvax is IERC20 {
    function getSharesByPooledAvax(uint avaxAmount) external view returns (uint);
    function getPooledAvaxByShares(uint shareAmount) external view returns (uint);
    function submit() external payable returns (uint);
}