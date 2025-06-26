// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRaffle {
    function startRaffle() external;
    function pickWinner() external;
    function raffleCounterId() external view returns(uint128);
}
