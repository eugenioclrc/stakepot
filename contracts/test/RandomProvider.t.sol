// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/RandomProvider.sol";
import "src/mocks/MockVRFCoordinator.sol";

contract MockRaffle {
    uint256 public raffleCounterId;
    function callRequest(RandomProvider requester) external {
        requester.requestRandomNumber(false);
        raffleCounterId++;
    }
}

contract MockRandomProvider is RandomProvider {
    // Test-only function to simulate VRF coordinator callback
    address _vrfCoordinator;
    uint256 subscriptionId;
    bytes32 _keyHash;
    address _raffle;

    constructor(address _vrfCoordinator_, uint256 _subscriptionId, bytes32 _keyHash_, address _raffle_)
        RandomProvider(_vrfCoordinator_, _subscriptionId, _keyHash_,  _raffle_)
    {}

    function testFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
        // Only allow this in test environment
        require(block.chainid == 31337 || block.chainid == 1337, "Test only");
        fulfillRandomWords(requestId, randomWords);
    }
}

contract RandomProviderTest is Test {
    RandomProvider requester;
    MockVRFCoordinator coordinator;
    MockRaffle raffle;

    address owner = address(this);
    bytes32 keyHash = keccak256("key");
    uint256 subId = 1;

    function setUp() public {
        coordinator = new MockVRFCoordinator();
        raffle = new MockRaffle();
        requester =
            RandomProvider(address(new MockRandomProvider(address(coordinator), subId, keyHash, address(raffle))));
    }

    function testInitialSetup() public {
        assertEq(requester.s_subscriptionId(), subId);
        assertEq(requester.keyHash(), keyHash);
        assertEq(address(requester.raffle()), address(raffle));
    }

    function testOnlyRaffleCanRequest() public {
        vm.expectRevert("ONLY_RAFFLE");
        requester.requestRandomNumber(false);
    }

    function testRequestRandomNumberFromRaffle() public {
        // Llama desde contrato mock que simula la raffle
        raffle.callRequest(requester);

        assertEq(requester.lastRequestId(), uint256(keccak256("mockedRequestId")));
        assertEq(coordinator.lastKeyHash(), keyHash);
        assertEq(coordinator.lastSubId(), subId);
        assertEq(coordinator.lastConfirmations(), 3);
        assertEq(coordinator.lastGasLimit(), 100_000);
        assertEq(coordinator.lastNumWords(), 1);
    }

    function testFulfillRandomWordsUpdatesLastRandom() public {
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 777;
        MockRandomProvider(address(requester)).testFulfillRandomWords(0, randomWords);
        assertEq(uint256(requester.randomValue(0)), 777);
    }

    function testSetCallbackGasLimit() public {
        requester.setCallbackGasLimit(250_000);
        assertEq(requester.callbackGasLimit(), 250_000);
    }

    function testSetRequestConfirmations() public {
        requester.setRequestConfirmations(5);
        assertEq(requester.requestConfirmations(), 5);
    }

    function testSetRaffle() public {
        address newRaffle = address(0xABCD);
        requester.setRaffle(newRaffle);
        assertEq(address(requester.raffle()), newRaffle);
    }

    error Unauthorized();

    function testOnlyOwnerModifiers() public {
        address notOwner = address(0xBEEF);

        vm.prank(notOwner);
        vm.expectRevert(Unauthorized.selector);
        requester.setRaffle(address(0xDEAD));

        vm.prank(notOwner);
         vm.expectRevert(Unauthorized.selector);
        requester.setCallbackGasLimit(9999);
    }
}
