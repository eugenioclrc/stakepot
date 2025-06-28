// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "solady/src/auth/Ownable.sol";

import {RandomProvider} from "./RandomProvider.sol";
import {Vault} from "./VaultBenji.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/Test.sol";

contract Raffle is Ownable {
    event WinnerPicked(uint256 raffleCounterId, Ticket ticket);

    struct Ticket {
        uint128 id;
        uint120 validAfter;
        bool burned;
        address owner;
    } // Packet in 2 slots

    uint8 internal constant RAFFLE_NOT_STARTED = 1;
    uint8 internal constant RAFFLE_STARTED = 2;
    uint256 public immutable TICKET_PRICE;
    Vault public immutable VAULT;

    uint256 public ticketCounterId;
    // use to continue the raffle if the gas is not enough
    bytes32 public latestPRGN;

    mapping(uint256 => Ticket) public tickets;
    uint128[] public validTickets;
    uint128[] public burnedTickets;

    uint128 public latestRaffleTime;
    uint128 public raffleCounterId;
    mapping(uint256 => uint256) public raffleTicketsWinner;

    address public keeper;
    RandomProvider public randomProvider;
    uint8 private _raffleState = 1; // 1: open, 2: closed

    constructor(uint256 _ticketPrice, address _keeper, address _randomProvider, address _vault, address _SAVAX) {
        TICKET_PRICE = _ticketPrice;
        randomProvider = RandomProvider(_randomProvider);
        keeper = _keeper;
        _initializeOwner(msg.sender);
        IERC20(_SAVAX).approve(_vault, type(uint256).max);
        VAULT = Vault(_vault);
    }

    modifier onlyKeeper() {
        require(msg.sender == keeper, "Not keeper");
        _;
    }

    function buyTickets() external payable {
        uint256 _tickets = msg.value / TICKET_PRICE;
        require(_tickets > 0, "No tickets purchased");
        require(msg.value % TICKET_PRICE == 0, "Incorrect amount sent");

        VAULT.deposit{value: msg.value}();

        uint256 counter = ticketCounterId;

        for (uint256 i = 0; i < _tickets; i++) {
            // @dev avoid safe cast because ticketCounterId is uint256 and counter will never exceed it
            // @dev validAfter avoid safe cast, uint120 is enough time
            tickets[counter] = Ticket(uint128(counter), uint120(block.timestamp + 1 days), false, msg.sender); // one day plus 1 second
            validTickets.push(uint128(counter));
            counter++;
        }
        ticketCounterId += _tickets;
    }

    function withdraw(uint256[] memory ticketsId) external {
        require(_raffleState == RAFFLE_NOT_STARTED, "Raffle started, cant withdraw");
        require(ticketsId.length > 0, "No tickets to withdraw");

        for (uint256 i = 0; i < ticketsId.length; i++) {
            uint256 ticketId = ticketsId[i];
            Ticket storage ticket = tickets[ticketId];

            require(ticket.owner == msg.sender, "You are not the owner of this ticket");
            require(!ticket.burned, "Ticket already burned");

            ticket.burned = true;
        }

        uint256 amount = TICKET_PRICE * ticketsId.length;
        VAULT.withdraw(msg.sender, amount);
    }

    function startRaffle() external onlyKeeper {
        require(_raffleState == RAFFLE_NOT_STARTED, "Raffle already started");
        _raffleState = 2; // close raffle
        latestRaffleTime = uint128(block.timestamp);
        randomProvider.requestRandomNumber();
    }

    function pickWinner() external {
        require(gasleft() >= 60000, "use min of 60k gas");
        require(_raffleState == RAFFLE_STARTED, "Raffle not started");
        bytes32 prng = latestPRGN == bytes32(0) ? randomProvider.randomValue(raffleCounterId) : latestPRGN;
        require(uint256(prng) > 0, "RND_NOT_SET");

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
                latestPRGN = bytes32(0);
                emit WinnerPicked(raffleCounterId, ticket);
            } else {
                prng = keccak256(abi.encodePacked(prng, winner));
            }
            if (gasleft() < 25000) {
                latestPRGN = prng;
                // early exit, needs to re-run the function with the latest PRNG
                return;
            }
        }

        raffleCounterId++;
        latestRaffleTime = uint128(block.timestamp);
        // reset raffle state
        _raffleState = RAFFLE_NOT_STARTED;

        VAULT.withdrawToWinner(foundWinner);
    }

    function cleanup(uint256 amountToProcess) external {
        if (_raffleState == RAFFLE_STARTED) {
            require(msg.sender == owner(), "Only owner can cleanup if raffle started");
        }

        if (amountToProcess == 0) {
            amountToProcess = burnedTickets.length;
        } else {
            amountToProcess = amountToProcess > burnedTickets.length ? burnedTickets.length : amountToProcess;
        }

        for (uint256 i = 0; i < amountToProcess; i++) {
            uint128 burnId = burnedTickets[burnedTickets.length - 1];
            burnedTickets.pop();
            Ticket storage ticket = tickets[burnId];
            if (ticket.burned) {
                _remove(burnId);
                delete tickets[burnId];
            }
        }
    }

    function _remove(uint128 id) internal {
        uint128[] storage _validTickets = validTickets; // copy to memory for gas efficiency
        for (uint256 i = 0; i < _validTickets.length; i++) {
            if (_validTickets[i] == id) {
                _validTickets[i] = _validTickets[_validTickets.length - 1];
                _validTickets.pop();
                return;
            }
        }
    }

    function pricePool() external view virtual returns (uint256) {
        return VAULT.totalPrice();
    }

    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
    }

    function setRandomProvider(address _randomProvider) external onlyOwner {
        randomProvider = RandomProvider(_randomProvider);
    }
}
