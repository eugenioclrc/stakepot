// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import {Ownable} from "solady/src/auth/Ownable.sol";
import {IRaffle} from "./interfaces/IRaffle.sol";

contract DailyTask is AutomationCompatibleInterface, Ownable {
    IRaffle public RAFFLE;
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
        upkeepNeeded = _upkeepNeeded();
    }

    function _upkeepNeeded() internal view returns (bool) {
        if(address(RAFFLE) == address(0)) {
            return false;
        }

        if ((block.timestamp - lastTimeStamp) < interval) {
            // need more time
            return false;
        } else if (paused()) {
            // contract is paused
            return false;
        } else if (RAFFLE.pricePool() == 0) {
            // no price pool
            return false;
        }
        return true;
    }

    function performUpkeep(bytes calldata) external override {
        require(_upkeepNeeded(), "NO_UPKEEPNEED");
        lastTimeStamp = block.timestamp;
        RAFFLE.startRaffle();
    }

    // === Admin Functions ===
    function setInterval(uint256 _interval) external onlyOwner {
        interval = _interval;
    }

    function setRaffle(address _raffle) external onlyOwner {
        RAFFLE = IRaffle(_raffle);
    }

    function pause() external onlyOwner {
        _paused = 2;
    }

    function unpause() external onlyOwner {
        _paused = 1;
    }
}
