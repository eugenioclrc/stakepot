// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "solady/src/auth/Ownable.sol";

import {RandomProvider} from "./RandomProvider.sol";
import {Vault} from "./VaultBenji.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Raffle is Ownable {
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

        VAULT.withdrawToWinner(foundWinner);
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
