// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiWallet.sol";

contract multiTest is Test {
    MultiWallet wallet;

    address user1 = address(1);
    uint constant DEPOSIT = 1 ether;

    function setUp() public {
        wallet = new MultiWallet();
        vm.deal(user1, 10 ether);
    }

    function testUserCanDeposit() public {
        vm.prank(user1);
        wallet.deposit{value: DEPOSIT}();

        uint count = wallet.getUserDepositCounts(user1);
        assertEq(count, 1);

        (uint amount, uint unlockTime) = wallet.getDeposit(user1, 0);

        assertEq(amount, DEPOSIT);
        assertEq(unlockTime, block.timestamp + 7 days);
    }

    function testUserCanDepositMultipleTimes() public {
        vm.prank(user1);
        wallet.deposit{value: DEPOSIT}();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        wallet.deposit{value: 2 ether}();

        uint count = wallet.getUserDepositCounts(user1);
        assertEq(count, 2);

        (uint storeAmount1, uint unlockTime1) = wallet.getDeposit(user1, 0);
        assertEq(storeAmount1, DEPOSIT);

        (uint storeAmount2, uint unlockTime2) = wallet.getDeposit(user1, 1);
        assertEq(storeAmount2, 2 ether);

        assertTrue(unlockTime1 < unlockTime2);
    }

    function testCantWithdrawBefore7Days() public {
        vm.prank(user1);
        wallet.deposit{value: DEPOSIT}();

        vm.expectRevert("Time not reached");
        vm.prank(user1);
        wallet.withdraw(0);
    }

    function testCanWithdrawOneDeposit() public {
        vm.prank(user1);
        wallet.deposit{value: DEPOSIT}();

        vm.warp(block.timestamp + 1 days);

        vm.prank(user1);
        wallet.deposit{value: 2 ether}();

        vm.warp(block.timestamp + 7 days);

        vm.prank(user1);
        wallet.withdraw(0);

        (uint amount1,) = wallet.getDeposit(user1, 0);
        assertEq(amount1, 0);

        (uint amount2,) = wallet.getDeposit(user1, 1);
        assertEq(amount2, 2 ether);
    }

    function testCantWithdrawSameDeposit() public {
        vm.prank(user1);
        wallet.deposit{value: DEPOSIT}();

        vm.warp(block.timestamp + 7 days);

        vm.prank(user1);
        wallet.withdraw(0);

        vm.expectRevert("Already withdrawn");
        vm.prank(user1);
        wallet.withdraw(0);
    }
}