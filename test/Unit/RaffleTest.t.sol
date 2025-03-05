// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract RaffleTest is Test {
    Raffle public raffle;
    HelperConfig public helperConfig;

    uint256 entranceFee;
    uint256 interval;
    address vrfCoordinator;
    bytes32 gasLane;
    uint256 callbackGasLimit;
    uint256 subscriptionId;

    address public PLAYER = makeAddr("PLAYER");
    uint256 public constant STARTING_BALANCE = 100 ether;

    function setUp() public {

        DeployRaffle deployer = new DeployRaffle();

        (raffle, helperConfig) = deployer.deployContract();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
        entranceFee = config.entranceFee;
        interval = config.interval;
        vrfCoordinator = config.vrfCoordinator;
        gasLane = config.gasLane;
        callbackGasLimit = config.callbackGasLimit;
        subscriptionId = config.subscriptionId;
        
    }

    function test_RaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() ==  Raffle.RaffleState.OPEN);
    }
    function testRaffleRevertsWhenNotEnoughEthIsSent() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle__SendMoreToEnterRaffle.selector);
        raffle.enterRaffle();
    }

}