
// SPDX-License-Identifier: MIT

// Layout of the contract file:
// version
// imports
// errors
// interfaces, libraries, contract

// Inside Contract:
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private

// view & pure functions
pragma solidity ^0.8.19;
import {VRFConsumerBaseV2Plus} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "lib/chainlink-brownie-contracts/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";
contract Raffle is VRFConsumerBaseV2Plus {
        //errors 
    error Raffle__TransferFailed();
    error Raffle__NotEnoughEth();
    error Raffle__RaffleNotOpen();
    error Raffle_UpKeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);
    uint32 private constant NUM_WORDS = 1;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;


    //state variables
    //type declarations
    enum RaffleState {
        OPEN,
        CALCULATING
    }
    
    uint256 private immutable i_entranceFee;
    // @dev the duration of the raffle
    uint256 private immutable i_interval;
    uint32 private immutable i_callbackGasLimit = 100000;
    bytes32 private immutable i_keyHash;

    uint64 private immutable i_subscriptionId;
    uint256 private s_lastTimestamp;
    address payable[] private s_players;
    address private s_recentWinner;
    RaffleState private s_raffleState;
    //events
    event RaffleEnter(address indexed player, uint256 indexed id);
    event WinnerPicked(address indexed winner);

    constructor(uint256 entranceFee, uint256 interval, address vrfCoordinator, bytes32 gasLane, uint256 subId, uint32 callbackGasLimit) VRFConsumerBaseV2Plus(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_lastTimestamp = block.timestamp;
        s_vrfCoordinator.requestRandomWords();
        i_keyHash = gasLane;
        i_subscriptionId = subId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        }
    

    function enterRaffle() external payable {
            if (msg.value < i_entranceFee) {
                revert Raffle__NotEnoughEth();
            }
            if (s_raffleState != RaffleState.OPEN) {
                revert Raffle__RaffleNotOpen();
            }
            s_players.push(payable(msg.sender));
            emit RaffleEnter(msg.sender, s_players.length - 1);
    }
    

    function checkUpkeep(bytes memory /* checkData */) public view 
        returns (bool upkeepNeeded, bytes memory /* performData */)
    {
        bool timeHasPassed =  ((block.timestamp - s_lastTimestamp) > i_interval);
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;
        upkeepNeeded = (timeHasPassed && isOpen && hasBalance && hasPlayers);
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert Raffle_UpKeepNotNeeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        if (block.timestamp - s_lastTimestamp < i_interval) {
            revert();
        }
        s_raffleState = RaffleState.CALCULATING;
        VTFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest(
            {
                keyHash: i_keyHash,
                subId: i_subscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    // Set nativePayment to true to pay for VRF requests with Sepolia ETH instead of LINK
                    VRFV2PlusClient.ExtraArgsV1({nativePayment: false})
                )
            });
    
        
        uint256 requestId = s_vrfCoordinator.requestRandomWords(

        );

    }


    //get random number
    // use rng to pick a player
    //be automatically called
    function pickWinner() external {

    }

    //CEI: checks,effects,interactions
    function fulfillRandomWords(uint256 requestId, uint256[] calldata randomWords) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfWinner];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        emit WinnerPicked(s_recentWinner);

        (bool success, ) = recentWinner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        
    }

    //getters
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

}
