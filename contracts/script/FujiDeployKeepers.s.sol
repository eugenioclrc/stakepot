// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
//import {Counter} from "../src/Counter.sol";
import {MockStakedAvax} from "../src/mocks/MockStakedAvax.sol";
import {Vault} from "../src/VaultBenji.sol";
import {DailyTask} from "../src/DailyTask.sol";
import {Raffle} from "../src/Raffle.sol";
import {RandomProvider} from "../src/RandomProvider.sol";
import {DailyPickWinnerTask} from "../src/DailyPickwinner.sol";

contract FujiDeployKeepersScript is Script {
    //Counter public counter;

    function setUp() public {
        require(block.chainid == 43113, "Not Fuji");

    }

    function run() public returns ( DailyTask dailyTask, DailyPickWinnerTask dailyPickWinnerTask) {
        vm.startBroadcast();
        
        dailyTask = new DailyTask(address(0));
        dailyPickWinnerTask = new DailyPickWinnerTask(address(0));

        vm.stopBroadcast();
    }
}
