// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRaffle {
    function startRaffle() external;
    function pickWinner(bytes32 prng) external;
}
