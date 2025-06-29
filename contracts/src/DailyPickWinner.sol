// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {IRaffle} from "./interfaces/IRaffle.sol";

contract DailyPickWinnerTask is AutomationCompatibleInterface, Ownable {
    IRaffle public RAFFLE;


    constructor(address _raffle) {
        _initializeOwner(msg.sender);
        RAFFLE = IRaffle(_raffle);
    }


    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = _upkeepNeeded();
    }

    function _upkeepNeeded() internal view returns (bool) {
        return address(RAFFLE) != address(0) && RAFFLE.raffleState() == 2;
    }

    function performUpkeep(bytes calldata) external override {
        require(_upkeepNeeded(), "NO_UPKEEPNEED");
        RAFFLE.pickWinner();
    }

    function setRaffle(address _raffle) external onlyOwner {
        RAFFLE = IRaffle(_raffle);
    }
}
