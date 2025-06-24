// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract RandomRequester is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface public COORDINATOR;

    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100_000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;

    uint256 public lastRequestId;
    uint256 public lastRandom;

    address public owner;

    constructor(address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        owner = msg.sender;
    }

    function requestRandomNumber() external {
        require(msg.sender == owner, "Only owner");
        lastRequestId =
            COORDINATOR.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        lastRandom = randomWords[0];
        // Aquí podés usar el random como quieras
    }
}
