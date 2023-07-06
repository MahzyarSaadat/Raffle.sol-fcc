//Raffle

//Enter the lottery (paying some amount)
//Pick a random number (verifiably random)
//Chainlink Oracles -> randomness , automated execution (chinlink keepers)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

error Raffle__NotEnoughPaied();
error Raffle__TransactionFail();
error Raffle__NotOpen();
error Raffle__UpkeepNeeded(uint256 currentBalance, uint256 playerLength, uint256 raffleState);

/**
 * @title A sample Raffle contract
 * @author mahziar saadat
 * @notice this contract is creating for untamprable decentralized smart contract
 * @dev this implements chinlink VRF2 & chainlink Keepers
 */

contract Raffle is VRFConsumerBaseV2, AutomationCompatibleInterface {
    /* Type defintion*/
    enum RaffleState {
        OPEN,
        CALCULATING
    }

    //State variables
    uint256 private immutable i_entraceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint16 private constant REQUEST_CONFIRMATION = 3;
    uint32 private immutable i_callbackGasLimit;
    uint32 private constant NUM_WORDS = 1;

    //Lottery variables
    address private s_recentWinner;
    RaffleState private s_raffleState;
    uint256 private s_lastBlockTimestamp;
    uint256 private immutable i_interval;

    //Events
    event RaffleEnter(address indexed player);
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed winner);

    //functions
    constructor(
        address VRFConrdinatorV2,
        uint256 MinimumAmount,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit,
        uint256 interval
    ) VRFConsumerBaseV2(VRFConrdinatorV2) {
        i_entraceFee = MinimumAmount;
        i_vrfCordinator = VRFCoordinatorV2Interface(VRFConrdinatorV2);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        s_lastBlockTimestamp = block.timestamp;
        i_interval = interval;
    }

    function enterRaffle() public payable {
        //require(msg.sender > MinimumAmount , 'didn't send enogth')
        if (msg.value < i_entraceFee) {
            revert Raffle__NotEnoughPaied();
        }
        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__NotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEnter(msg.sender);
    }

    /**
     * @dev this is the function that the chainlink keeper nodes call
     * they look for "upKeepnedded" to return true
     * the folowing should be true in order to return true
     * 1. our time interval should have passed
     * 2. the lottery should have at least 1 player , and have some ETH
     * 3. our subscription funded with link
     * 4. the lottery should be an "open " state
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = (RaffleState.OPEN == s_raffleState);
        bool timePassed = ((block.timestamp - s_lastBlockTimestamp) > i_interval);
        bool hasPlayers = (s_players.length > 0);
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        //Request random number
        //Once we get it , we do something with it
        //2 transaction process
        (bool upKeepNeeded, ) = checkUpkeep("");
        if (!upKeepNeeded) {
            revert Raffle__UpkeepNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        uint256 requestId = i_vrfCordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATION,
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit RequestedRaffleWinner(requestId);
    }

    function fulfillRandomWords(
        uint256 /*requestId*/,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastBlockTimestamp = block.timestamp;
        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransactionFail();
        }
        emit WinnerPicked(recentWinner);
    }

    function getEntraceFee() public view returns (uint256) {
        return i_entraceFee;
    }

    function getPlayers(uint256 index) public view returns (address) {
        return s_players[index];
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getRaffleState() public view returns (RaffleState) {
        return s_raffleState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getNumberPlayers() public view returns (uint256) {
        return s_players.length;
    }

    function LatestTimeStamp() public view returns (uint256) {
        return s_lastBlockTimestamp;
    }

    function getRequestConfirmation() public pure returns (uint256) {
        return REQUEST_CONFIRMATION;
    }
}
