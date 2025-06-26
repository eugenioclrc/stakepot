// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {DailyTask} from "src/DailyTask.sol";
import {Raffle} from "src/Raffle.sol";

contract MockRaffle {
    bool public wasCalled;

    // starts with a price pool
    uint256 _pricePool = 10;

    function startRaffle() external {
        wasCalled = true;
    }

    function pricePool() external view returns (uint256) {
        return _pricePool;
    }

    function setPricePool(uint256 price) external {
        _pricePool = price;
    }
}

contract DailyTaskTest is Test {
    error Unauthorized();

    DailyTask public task;
    MockRaffle public raffle;
    address public owner = address(this);
    address public stranger = address(0xBEEF);

    function setUp() public {
        raffle = new MockRaffle();
        task = new DailyTask(address(raffle));
    }

    function testInitialState() public {
        assertEq(task.paused(), false);
        assertEq(task.interval(), 1 days);
        assertEq(address(task.RAFFLE()), address(raffle));
    }

    function testCheckUpkeepNotNeededInitially() public {
        (bool upkeepNeeded,) = task.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepNeededAfterInterval() public {
        vm.warp(block.timestamp + 1 days + 1);
        (bool upkeepNeeded,) = task.checkUpkeep("");
        assertTrue(upkeepNeeded);

        task.pause();
        (upkeepNeeded,) = task.checkUpkeep("");
        assertFalse(upkeepNeeded);

        task.unpause();
        (upkeepNeeded,) = task.checkUpkeep("");
        assertTrue(upkeepNeeded);

        raffle.setPricePool(0);
        (upkeepNeeded,) = task.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function testPerformUpkeepCallsRaffleWhenNotPaused() public {
        vm.warp(block.timestamp + 1 days + 1);
        task.performUpkeep("");
        assertTrue(raffle.wasCalled());
        assertEq(task.lastTimeStamp(), block.timestamp);
    }

    function testPerformUpkeepRevertsWhenPaused() public {
        task.pause();
        vm.warp(block.timestamp + 2 days);

        vm.expectRevert("NO_UPKEEPNEED");
        task.performUpkeep("");
    }

    function testPauseAndUnpause() public {
        assertEq(task.paused(), false);
        task.pause();
        assertEq(task.paused(), true);
        task.unpause();
        assertEq(task.paused(), false);
    }

    function testOnlyOwnerCanPauseUnpauseAndSetInterval() public {
        vm.prank(stranger);
        vm.expectRevert(Unauthorized.selector);
        task.pause();

        vm.prank(stranger);
        vm.expectRevert(Unauthorized.selector);
        task.unpause();

        vm.prank(stranger);
        vm.expectRevert(Unauthorized.selector);
        task.setInterval(2 days);
    }

    function testSetInterval() public {
        task.setInterval(2 days);
        assertEq(task.interval(), 2 days);
    }

    function testPerformUpkeepBeforeIntervalDoesNothing() public {
        vm.expectRevert("NO_UPKEEPNEED");
        task.performUpkeep("");
        assertFalse(raffle.wasCalled());
    }

    function testMultipleUpkeeps() public {
        vm.warp(block.timestamp + 2 days);
        task.performUpkeep("");
        assertTrue(raffle.wasCalled());

        // Reset
        raffle = new MockRaffle();
        vm.warp(block.timestamp + 1 days);
        task.performUpkeep(""); // Debe volver a llamarse porque pasó otro día
            // Pero como usamos otro MockRaffle, el flag `wasCalled` está en el contrato anterior
            // Este caso ilustra que se puede repetir upkeep si pasa suficiente tiempo
    }
}
