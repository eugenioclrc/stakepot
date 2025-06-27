// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/VaultBenji.sol";
import "src/mocks/MockStakedAvax.sol";

contract VaultTest is Test {
    error Unauthorized();

    Vault vault;
    MockStakedAvax mockSAVAX;
    address raffle = address(0xBEEF);
    address winner = address(0xCAFE);
    address nonRaffle = address(0xBAD);

    function setUp() public {
        mockSAVAX = new MockStakedAvax();
        vault = new Vault(address(mockSAVAX));
        vault.setRaffle(raffle);
        vm.deal(raffle, 100 ether);
        vm.deal(address(nonRaffle), 100 ether);

        vm.prank(raffle);
        mockSAVAX.approve(address(vault), type(uint256).max);
    }

    function testDepositRevertsIfNotRaffle() public {
        vm.expectRevert("ONLY_RAFFLE");
        vm.prank(nonRaffle);
        vault.deposit{value: 1 ether}();
    }

    function testDepositSubmitsToStakedAvax() public {
        vm.prank(raffle);
        vault.deposit{value: 1 ether}();
        assertEq(mockSAVAX.balanceOf(address(vault)), 1 ether);
    }

    function testDepositSAVAXIncreasesTotalBalance() public {
        deal(address(mockSAVAX), 2 ether);
        deal(address(mockSAVAX), address(raffle), 2 ether);
        vm.prank(raffle);
        vault.depositSAVAX(2 ether);
        assertEq(mockSAVAX.balanceOf(address(vault)), 2 ether);
    }

    function testDepositSAVAXRevertsIfNotRaffle() public {
        vm.expectRevert("ONLY_RAFFLE");
        vm.prank(nonRaffle);
        vault.depositSAVAX(1 ether);
    }

    function testWithdrawTransfersCorrectAmount() public {
        deal(address(mockSAVAX), 10 ether);
        deal(address(mockSAVAX), address(raffle), 10 ether);
        vm.prank(raffle);
        vault.depositSAVAX(10 ether);

        address bob = makeAddr("bob");
        vm.prank(raffle);
        vault.withdraw(bob, 4 ether);
        assertEq(mockSAVAX.balanceOf(bob), 4 ether);
    }

    function testWithdrawRevertsIfNotRaffle() public {
        vm.expectRevert("ONLY_RAFFLE");
        vm.prank(nonRaffle);
        vault.withdraw(address(1), 1 ether);
    }

    function testWithdrawToWinnerTransfersIfGain() public {
        deal(address(mockSAVAX), 10 ether);
        deal(address(mockSAVAX), address(raffle), 10 ether);
        vm.prank(raffle);
        vault.depositSAVAX(10 ether); // totalBalance = 10

        vm.warp(block.timestamp + 10 days);

        vm.prank(raffle);
        vault.withdrawToWinner(winner);
        // earns from aprox yield
        assertApproxEqAbs(mockSAVAX.balanceOf(winner), 1 ether, 0.1 ether);
    }

    function testWithdrawToWinnerNoTransferIfNoGain() public {
        deal(address(mockSAVAX), 10 ether);
        deal(address(mockSAVAX), address(raffle), 10 ether);
        vm.prank(raffle);
        vault.depositSAVAX(10 ether); // totalBalance = 10

        vm.prank(raffle);
        vault.withdrawToWinner(winner);
        assertEq(mockSAVAX.balanceOf(winner), 0);
    }

    function testTotalPriceReturnsCorrectAmount() public {
        deal(address(mockSAVAX), 10 ether);
        deal(address(mockSAVAX), address(raffle), 10 ether);
        vm.prank(raffle);
        vault.depositSAVAX(10 ether);

        vm.warp(block.timestamp + 10 days);

        uint256 price = vault.totalPrice();
        assertEq(price, 1 ether);
    }

    function testSetRaffleOnlyOwner() public {
        vm.prank(nonRaffle);
        vm.expectRevert(Unauthorized.selector);
        vault.setRaffle(nonRaffle);
    }

    function testSetRaffleRejectsZeroAddress() public {
        vm.expectRevert("NO_ZERO_ADDRESS");
        vault.setRaffle(address(0));
    }

    function testWithdrawStuckTransfersTokens() public {
        address token = address(new MockStakedAvax());
        vm.etch(token, hex"deadbeef"); // fake bytecode
        vm.expectRevert(); // esto fallará porque no hay implementación válida
        vault.withdrawStuck(token, 1 ether);
    }

    function testWithdrawStuckRejectsZeroAddress() public {
        vm.expectRevert("NO_ZERO_ADDRESS");
        vault.withdrawStuck(address(0), 1 ether);
    }

    function testWithdrawStuckRejectsZeroAmount() public {
        vm.expectRevert("NO_ZERO_AMOUNT");
        vault.withdrawStuck(address(mockSAVAX), 0);
    }

    // test price pool
    function testPricePool() public {
        deal(address(mockSAVAX), address(raffle), 10 ether);
        vm.prank(raffle);
        vault.depositSAVAX(10 ether);

        assertEq(vault.totalPrice(), 0);
        vm.warp(block.timestamp + 10 days);
        assertEq(vault.totalPrice(), 1 ether);
    }

    function testPriceRawPool() public {
        deal(raffle, 10 ether);
        vm.prank(raffle);
        vault.deposit{value: 10 ether}();

        assertEq(vault.totalPrice(), 0);
        vm.warp(block.timestamp + 1 days);
        assertEq(vault.totalPrice(), 0.1 ether);
    }
}
