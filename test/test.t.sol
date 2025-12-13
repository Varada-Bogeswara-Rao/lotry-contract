// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Counter.sol";

contract LotteryProtocolTest is Test {
    LotteryProtocol lottery;

    address owner = address(1);
    address player1 = address(2);
    address player2 = address(3);

    function setUp() public {
        vm.prank(owner);
        lottery = new LotteryProtocol(2, 10);

        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
    }

    function testStartLottery() public {
        vm.prank(owner);
        lottery.startLottery();

        assertEq(uint(lottery.lotteryState()), 0); // OPEN
    }

    function testPlayersCanEnter() public {
        vm.prank(owner);
        lottery.startLottery();

        vm.prank(player1);
        lottery.enter{value: 0.01 ether}();

        vm.prank(player2);
        lottery.enter{value: 0.01 ether}();

        assertEq(lottery.getPlayersCount(), 2);
    }

    function testEndLotteryPicksWinner() public {
        vm.prank(owner);
        lottery.startLottery();

        vm.prank(player1);
        lottery.enter{value: 0.01 ether}();

        vm.prank(player2);
        lottery.enter{value: 0.01 ether}();

        vm.prank(owner);
        lottery.endLottery();

        assert(address(lottery.recentWinner()) != address(0));
    }
}
