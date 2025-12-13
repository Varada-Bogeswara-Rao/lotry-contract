// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Counter.sol";

contract DeployLottery is Script {
    function run() external {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerKey);

        // minPlayers = 2, maxPlayers = 10
        new LotteryProtocol(2, 10);

        vm.stopBroadcast();
    }
}
