// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/mocks/MockStackedAvax.sol";

contract MockStackedAvaxTest is Test {
    MockStackedAvax token;
    address user1;
    address user2;

    function setUp() public {
        token = new MockStackedAvax();
        user1 = address(0x1);
        user2 = address(0x2);
    }

    function testInitialDeployment() public {
        assertEq(token.name(), "MOCK Staked AVAX");
        assertEq(token.symbol(), "mSAVAX");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 10 ether);
        assertEq(token.balanceOf(address(this)), 10 ether);
        assertEq(token.totalAvax(), 10 ether);
    }

    function testSubmitMinting() public {
        vm.deal(user1, 5 ether);
        vm.prank(user1);
        token.submit{value: 5 ether}();
        assertEq(token.balanceOf(user1), 5 ether);
        assertEq(token.totalSupply(), 15 ether);
        // totalAvax no cambia en `submit`
        assertApproxEqAbs(token.totalAvax(), 10 ether, 1);
    }

    function testAirdropOnce() public {
        vm.prank(address(this));
        token.mintAirdrop(user1);
        assertGt(token.balanceOf(user1), 0);
    }

    function testCannotClaimAirdropTwice() public {
        vm.prank(address(this));
        token.mintAirdrop(user1);

        vm.expectRevert("Airdrop already claimed");
        vm.prank(address(this));
        token.mintAirdrop(user1);
    }

    function testAirdropIncreasesTotalAvax() public {
        uint256 avaxBefore = token.totalAvax();
        vm.prank(address(this));
        token.mintAirdrop(user1);
        assertGt(token.totalAvax(), avaxBefore);
    }

    function testGetPooledAvaxByShares() public {
        vm.prank(address(this));
        token.mintAirdrop(user1);

        uint256 shares = token.balanceOf(user1);
        uint256 expectedAvax = token.totalAvax() * shares / token.totalSupply();
        uint256 pooledAvax = token.getPooledAvaxByShares(shares);
        assertEq(pooledAvax, expectedAvax);
    }

    function testGetSharesByPooledAvax() public {
        vm.prank(address(this));
        token.mintAirdrop(user1);

        uint256 avax = 10 ether;
        uint256 expectedShares = token.totalSupply() * avax / token.totalAvax();
        uint256 shares = token.getSharesByPooledAvax(avax);
        assertEq(shares, expectedShares);
    }

    function testTotalAvaxIncreasesOverTime() public {
        uint256 base = token.totalAvax();
        vm.warp(block.timestamp + 10 days);
        uint256 increased = token.totalAvax();
        assertGt(increased, base);
        uint256 expected = base + (base * 10 / 100); // ~1% per day
        assertApproxEqAbs(increased, expected, 1e14);
    }
}
