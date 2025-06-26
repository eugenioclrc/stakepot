// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "solady/src/auth/Ownable.sol";

import {RandomProvider} from "./RandomProvider.sol";


contract Raffle is Ownable {
    struct Ticket {
        uint128 id;
        uint120 validAfter;
        bool burned;
        address owner;
    }

    uint8 internal constant RAFFLE_NOT_STARTED = 1;
    uint8 internal constant RAFFLE_STARTED = 2;
    uint256 public immutable TICKET_PRICE;

    uint256 public ticketCounterId;

    mapping(uint256 => Ticket) public tickets;
    uint128[] public validTickets;
    uint128[] public burnedTickets;

    uint128 public latestRaffleTime;
    uint128 public raffleCounterId;
    mapping(uint256 => uint256) public raffleTicketsWinner;

    address public keeper;
    RandomProvider public randomProvider;
    uint8 private _raffleState = 1; // 1: open, 2: closed

    constructor(uint256 _ticketPrice, address _keeper, address _randomProvider) {
        TICKET_PRICE = _ticketPrice;
        randomProvider = RandomProvider(_randomProvider);
        keeper = _keeper;
        _initializeOwner(msg.sender);
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "Not keeper");
        _;
    }

    function startRaffle() external onlyKeeper {
        require(_raffleState == RAFFLE_NOT_STARTED, "Raffle already started");
        _raffleState = 2; // close raffle
        latestRaffleTime = uint128(block.timestamp);
        randomProvider.requestRandomNumber();
    }

    // @TODO Need some tweaks here to avoid any DOS / out of gas issues, for now its ok
    function pickWinner() external {
        require(_raffleState == RAFFLE_STARTED, "Raffle not started");
        bytes32 prng = randomProvider.randomValue(raffleCounterId);
        require(prng != bytes32(0x00), "RND_NOT_SET");

        uint128[] memory _validTickets = validTickets; // copy to memory for gas efficiency
        uint256 lenValidTickets = _validTickets.length;

        address foundWinner = address(0);

        while (foundWinner == address(0)) {
            uint256 winner = uint256(prng) % lenValidTickets;
            uint256 ticketId = _validTickets[winner];
            Ticket storage ticket = tickets[ticketId];
            if (ticket.validAfter < block.timestamp && !ticket.burned) {
                raffleTicketsWinner[raffleCounterId] = ticketId;
                foundWinner = ticket.owner;
            } else {
                prng = keccak256(abi.encodePacked(prng, winner));
            }
        }

        raffleCounterId++;
        latestRaffleTime = uint128(block.timestamp);
        // reset raffle state
        _raffleState = RAFFLE_NOT_STARTED;

        // TODO transfer the price to foundWinner
    }

    

    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
    }

    function setRandomProvider(address _randomProvider) external onlyOwner {
        randomProvider = RandomProvider(_randomProvider);
    }
}
