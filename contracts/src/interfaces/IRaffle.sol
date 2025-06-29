// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRaffle {
    function startRaffle() external;
    function pickWinner() external;
    function pricePool() external view returns (uint256);
    function raffleState() external view returns (uint8);
    function raffleCounterId() external view returns (uint128);
}
