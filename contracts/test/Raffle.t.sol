// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {Vault} from "src/VaultBenji.sol";
import {MockStakedAvax} from "src/mocks/MockStakedAvax.sol";
import {Raffle} from "src/Raffle.sol";
import {RandomProvider} from "src/RandomProvider.sol";
import {DailyTask} from "src/DailyTask.sol";
import {VRFCoordinatorV2_5Mock} from "src/mocks/VRFCoordinatorV2_5Mock.sol";



contract MockRandomProvider is RandomProvider {
    // Test-only function to simulate VRF coordinator callback
    constructor(address _vrfCoordinator, uint256 _subscriptionId, bytes32 _keyHash, address _raffle)
        RandomProvider(_vrfCoordinator, _subscriptionId, _keyHash,_raffle)
    {}

    function testFulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) external {
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
    VRFCoordinatorV2_5Mock coordinator;

    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        coordinator = new VRFCoordinatorV2_5Mock(100000000000000000, 1000000000, 5466202833173323);
        mockSAVAX = new MockStakedAvax();
        vault = new Vault(address(mockSAVAX));
        dailyTask = new DailyTask(address(this));
        uint256 ticketPrice = 1 ether; // one avax per ticket
        raffle =
            new Raffle(ticketPrice, address(dailyTask), address(randomProvider), address(vault), address(mockSAVAX));
        randomProvider = new MockRandomProvider(address(coordinator), 1, bytes32(0), address(raffle));

        coordinator.addConsumer(uint256(1),address(randomProvider));

        raffle.setRandomProvider(address(randomProvider));
        dailyTask.setRaffle(address(raffle));
        vault.setRaffle(address(raffle));

        deal(alice, 10 ether);
        deal(bob, 10 ether);
    }

    function testRaffle() public {
        vm.prank(alice);
        raffle.buyTickets{value: 4 ether}();

        vm.prank(bob);
        raffle.buyTickets{value: 4 ether}();

        vm.prank(alice);
        raffle.buyTickets{value: 1 ether}();

        vm.prank(bob);
        raffle.buyTickets{value: 1 ether}();

        assertEq(raffle.pricePool(), 0 ether);

        assertEq(raffle.ticketCounterId(), 10);
        assertEq(raffle.pricePool(), 0 ether);
        vm.warp(block.timestamp + 1 days);

        assertGt(raffle.pricePool(), 0 ether);

        (bool upkeepNeeded,) = dailyTask.checkUpkeep("");
        assertTrue(upkeepNeeded);
        dailyTask.performUpkeep("");

        (upkeepNeeded,) = dailyTask.checkUpkeep("");
        assertFalse(upkeepNeeded);

        assertEq(raffle.pricePool(), 0.1 ether);

        uint256[] memory words = new uint256[](1);
        words[0] = uint256(keccak256(abi.encodePacked("random")));
        MockRandomProvider(address(randomProvider)).testFulfillRandomWords(1, words);

        // with current random the winner is alice (ticket 2)
        assertEq(mockSAVAX.balanceOf(alice), 0);

        // here no ticket is valid yet, so cant pick a winner
        raffle.pickWinner{gas: 1000000}();
        // but after 1 seconde the ticket are valid
        vm.warp(block.timestamp + 1);
        raffle.pickWinner{gas: 1000000}();

        assertEq(raffle.ticketCounterId(), 10);

        (uint128 id, uint120 validAfter, bool burned, address owner) = raffle.tickets(2);
        assertEq(id, 2);
        assertEq(owner, alice);
        assertEq(validAfter, 86401);
        assertFalse(burned);

        assertGt(mockSAVAX.balanceOf(alice), 0, "alice should have some savax after winning");
    }

    // ───────────────────────────────────────────── added: tests for withdraw ─┐
    function testWithdraw_RefundsAndBurns() public {
        // Alice buys 3 tickets (IDs 0,1,2)
        vm.prank(alice);
        raffle.buyTickets{value: 3 ether}();

        // she decides to refund the first two
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;

        vm.prank(alice);
        raffle.withdraw(ids);

        // both tickets are now burned
        (,, bool burned0,) = raffle.tickets(0);
        (,, bool burned1,) = raffle.tickets(1);
        assertTrue(burned0);
        assertTrue(burned1);

        // and Alice received 2 SAVAX (1 token per ticket)
        assertEq(mockSAVAX.balanceOf(alice), 2 ether);

        // withdrawing again must revert — already burned
        vm.prank(alice);
        vm.expectRevert("Ticket already burned");
        raffle.withdraw(ids);
    }

    function testWithdraw_RevertsIfNotOwnerOrStarted() public {
        // Alice buys 1, Bob buys 1
        vm.prank(alice);
        raffle.buyTickets{value: 1 ether}(); // id 0
        vm.prank(bob);
        raffle.buyTickets{value: 1 ether}(); // id 1

        // Bob tries to withdraw Alice’s ticket
        uint256[] memory wrong = new uint256[](1);
        wrong[0] = 0;
        vm.prank(bob);
        vm.expectRevert("You are not the owner of this ticket");
        raffle.withdraw(wrong);

        // start raffle
        vm.prank(address(dailyTask));
        raffle.startRaffle();

        // now even Alice can’t withdraw
        vm.prank(alice);
        vm.expectRevert("Raffle started, cant withdraw");
        raffle.withdraw(wrong);
    }

    // ───────────────────────────────────────────────────────────── helpers ─┐
    /// @dev storage slot of `burnedTickets` dynamic-array length (see layout)
    uint256 constant _BURNED_TICKETS_SLOT = 4;
    /// @dev storage slot of `validTickets` dynamic-array length
    uint256 constant _VALID_TICKETS_SLOT = 3;

    function _arrayLength(uint256 slot) internal view returns (uint256 len) {
        len = uint256(vm.load(address(raffle), bytes32(slot)));
    }

    /// @dev forcibly push an element to the `burnedTickets` array (test-only).
    function _cheatPushBurned(uint256 ticketId) internal {
        uint256 len = _arrayLength(_BURNED_TICKETS_SLOT);
        // increase length
        vm.store(address(raffle), bytes32(_BURNED_TICKETS_SLOT), bytes32(len + 1));
        // write element value
        bytes32 eltSlot = bytes32(uint256(keccak256(abi.encode(uint256(_BURNED_TICKETS_SLOT)))) + uint256(len));
        vm.store(address(raffle), eltSlot, bytes32(ticketId));
    }

    // ───────────────────────────────────────────── added: tests for cleanup ─┐
    function testCleanup_RemovesBurnedTickets() public {
        // 1) Alice buys 3 tickets (0,1,2) and burns #0 via withdraw
        vm.prank(alice);
        raffle.buyTickets{value: 3 ether}();

        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;
        vm.prank(alice);
        raffle.withdraw(ids);

        // 2) simulate the ticket being queued for cleanup
        _cheatPushBurned(0);

        uint256 lenBefore = _arrayLength(_VALID_TICKETS_SLOT);
        assertEq(lenBefore, 3, "setup sanity");

        // 3) anyone may call when raffle not started
        raffle.cleanup(0); // process all queued

        uint256 lenAfter = _arrayLength(_VALID_TICKETS_SLOT);
        assertEq(lenAfter, 2, "burned ticket removed from validTickets");

        // ticket mapping should be cleared
        (uint128 id,, bool burned, address owner) = raffle.tickets(0);
        assertEq(id, 0); // becomes default-value 0
        assertFalse(burned); // struct wiped
        assertEq(owner, address(0));
    }

    function testCleanup_OnlyOwnerWhenRaffleStarted() public {
        // Set the raffle to STARTED state
        vm.prank(address(dailyTask));
        raffle.startRaffle();

        // Bob (not owner) tries first
        vm.prank(bob);
        vm.expectRevert("Only owner can cleanup if raffle started");
        raffle.cleanup(0);

        // Owner is allowed
        raffle.cleanup(0);
    }
}
