// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "solady/src/auth/Ownable.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import {IRaffle} from "./interfaces/IRaffle.sol";

contract RandomProvider is VRFConsumerBaseV2, Ownable {
    VRFCoordinatorV2Interface public COORDINATOR;

    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit = 100_000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    
    mapping(uint256 raffleId => bytes32 random) public randomValue;

    uint256 public lastRequestId;

    IRaffle public raffle;

    constructor(address _vrfCoordinator, bytes32 _keyHash, uint64 _subscriptionId, address _raffle)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        keyHash = _keyHash;
        subscriptionId = _subscriptionId;
        _initializeOwner(msg.sender);
        raffle = IRaffle(_raffle);
    }

    function requestRandomNumber() external {
        require(msg.sender == address(raffle), "ONLY_RAFFLE");
        lastRequestId =
            COORDINATOR.requestRandomWords(keyHash, subscriptionId, requestConfirmations, callbackGasLimit, numWords);
    }

    function fulfillRandomWords(uint256, /* requestId */ uint256[] memory randomWords) internal override {
        randomValue[uint256(raffle.raffleCounterId())] = bytes32(randomWords[0]);
    }

    function setCallbackGasLimit(uint32 _callbackGasLimit) external onlyOwner {
        callbackGasLimit = _callbackGasLimit;
    }

    function setRequestConfirmations(uint16 _requestConfirmations) external onlyOwner {
        requestConfirmations = _requestConfirmations;
    }

    function setRaffle(address _raffle) external onlyOwner {
        raffle = IRaffle(_raffle);
    }
}
