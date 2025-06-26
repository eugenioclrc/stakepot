// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Vault} from "src/VaultBenji.sol";
import {MockStakedAvax} from "src/mocks/MockStakedAvax.sol";
import {Raffle} from "src/Raffle.sol";
import {RandomProvider} from "src/RandomProvider.sol";
import {DailyTask} from "src/DailyTask.sol";
import {MockVRFCoordinator} from "src/mocks/MockVRFCoordinator.sol";

contract MockRandomProvider is RandomProvider {
    // Test-only function to simulate VRF coordinator callback
    constructor(address _vrfCoordinator, bytes32 _keyHash, uint64 _subId, address _raffle)
        RandomProvider(_vrfCoordinator, _keyHash, _subId, _raffle)
    {}

    function testFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        // Only allow this in test environment
        require(block.chainid == 31337 || block.chainid == 1337, "Test only");
        fulfillRandomWords(requestId, randomWords);
    }
}

contract RaffleTest is Test {
    Raffle raffle;
    Vault vault;
    MockStakedAvax mockSAVAX;
    RandomProvider randomProvider;
    DailyTask dailyTask;
    MockVRFCoordinator coordinator;

    function setUp() public {
        coordinator = new MockVRFCoordinator();
        mockSAVAX = new MockStakedAvax();
        vault = new Vault(address(mockSAVAX));
        dailyTask = new DailyTask(address(this));
        uint256 ticketPrice = 1 ether;
        raffle =
            new Raffle(ticketPrice, address(dailyTask), address(randomProvider), address(vault), address(mockSAVAX));
        randomProvider = new MockRandomProvider(address(coordinator), bytes32(0), 1, address(raffle));

        raffle.setRandomProvider(address(randomProvider));
        dailyTask.setRaffle(address(raffle));
    }
}
