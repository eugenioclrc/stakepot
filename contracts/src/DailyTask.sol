// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";

interface IRaffle {
    function startRaffle() external;
}

contract DailyTask is AutomationCompatibleInterface, Ownable {
    IRaffle public immutable RAFFLE;
    uint256 public lastTimeStamp;
    uint256 public interval = 1 days;

    uint256 private _paused = 1;

    constructor(address _raffle) {
        lastTimeStamp = block.timestamp;
        _initializeOwner(msg.sender);
        RAFFLE = IRaffle(_raffle);
    }

    function paused() public view returns (bool) {
        return _paused != 1;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata) external override {
        require(!paused(), "PAUSED");
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
            // TODO call raffle
            RAFFLE.startRaffle();
        }
    }

    // === Admin Functions ===
    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
    }

    function pause() external onlyOwner {
        _paused = 2;
    }

    function unpause() external onlyOwner {
        _paused = 1;
    }
}
