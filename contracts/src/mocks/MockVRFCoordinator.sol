// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";

contract MockVRFCoordinator is VRFCoordinatorV2Interface {
    uint256 public lastRequestId;
    bytes32 public lastKeyHash;
    uint64 public lastSubId;
    uint16 public lastConfirmations;
    uint32 public lastGasLimit;
    uint32 public lastNumWords;

    function requestRandomWords(
        bytes32 keyHash_,
        uint64 subId_,
        uint16 confirmations_,
        uint32 gasLimit_,
        uint32 numWords_
    ) external override returns (uint256) {
        lastRequestId = uint256(keccak256("mockedRequestId"));
        lastKeyHash = keyHash_;
        lastSubId = subId_;
        lastConfirmations = confirmations_;
        lastGasLimit = gasLimit_;
        lastNumWords = numWords_;
        return lastRequestId;
    }

    // unused methods
    function getRequestConfig() external pure override returns (uint16, uint32, bytes32[] memory) {}

    // Add missing createSubscription function
    function createSubscription() external pure override returns (uint64 subId) {
        return 1; // Return a mock subscription ID
    }
    // Interface returns: (uint96 balance, uint64 reqCount, address owner, address[] memory consumers)
    // Interface returns: (uint96 balance, uint64 reqCount, address owner, address[] memory consumers)

    function getSubscription(uint64 subId)
        external
        pure
        override
        returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers)
    {
        // Return mock values in the correct order
        balance = 1000000000000000000; // 1 ETH in wei
        reqCount = 0;
        owner = address(0x123);
        consumers = new address[](0);
    }

    function requestSubscriptionOwnerTransfer(uint64, address) external pure override {}
    function acceptSubscriptionOwnerTransfer(uint64) external pure override {}
    function addConsumer(uint64, address) external pure override {}
    function removeConsumer(uint64, address) external pure override {}
    function cancelSubscription(uint64, address) external pure override {}
    function pendingRequestExists(uint64) external pure override returns (bool) {}
}
