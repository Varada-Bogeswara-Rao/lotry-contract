// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LotteryProtocol is Ownable, ReentrancyGuard {
    
    event LotteryStarted(uint256 indexed roundId);
    event PlayerEntered(uint256 indexed roundId, address indexed player);
    event WinnerPicked(uint256 indexed roundId, address indexed winner, uint256 prize);

    address payable[] public players;
    address payable public recentWinner;
    
    mapping(address => bool) public enteredThisRound;

    uint256 public constant ENTRY_FEE = 0.01 ether;

    uint256 public immutable minPlayers;
    uint256 public immutable maxPlayers;

    uint256 public currentRound;

    enum LOTTERY_STATE { OPEN, CLOSED }
    LOTTERY_STATE public lotteryState;

    constructor(
        uint256 _minPlayers,
        uint256 _maxPlayers
    ) Ownable(msg.sender) {
        require(_minPlayers >= 2, "Min players too low");
        require(_maxPlayers > _minPlayers, "Max must be > min");

        minPlayers = _minPlayers;
        maxPlayers = _maxPlayers;

        lotteryState = LOTTERY_STATE.CLOSED;
        currentRound = 0;
    }

    function startLottery() external onlyOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery already running");

        lotteryState = LOTTERY_STATE.OPEN;
        currentRound++;

        emit LotteryStarted(currentRound);
    }

    function enter() external payable {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(msg.value == ENTRY_FEE, "Incorrect ETH amount");
        require(players.length < maxPlayers, "Lottery full");
        require(!enteredThisRound[msg.sender], "Player already entered this round");

        players.push(payable(msg.sender));
        enteredThisRound[msg.sender] = true;

        emit PlayerEntered(currentRound, msg.sender);
    }

    function endLottery() external onlyOwner nonReentrant {
        require(lotteryState == LOTTERY_STATE.OPEN, "Lottery not open");
        require(players.length >= minPlayers, "Not enough players");

        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.prevrandao,
                    block.timestamp,
                    players.length,
                    currentRound
                )
            )
        );

        uint256 winnerIndex = random % players.length;
        recentWinner = players[winnerIndex];

        uint256 prize = address(this).balance;

        delete players;
        lotteryState = LOTTERY_STATE.CLOSED;

        (bool success, ) = recentWinner.call{value: prize}("");
        require(success, "ETH transfer failed");

        emit WinnerPicked(currentRound, recentWinner, prize);
    }

    function hasEntered() external view returns (bool) {
        return enteredThisRound[msg.sender];
    }

    function getPlayersCount() external view returns (uint256) {
        return players.length;
    }

    receive() external payable {}
}