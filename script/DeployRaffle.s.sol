// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployRaffle is Script, HelperConfig {
    function run() public {
        vm.startBroadcast();
        new Raffle();
        vm.stopBroadcast();
    }
    function deployContract() public returns (Raffle,HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        //local -> deploy mocks , get local config
        //sepolia -> get sepolia config
        helperConfig.NetworkConfig memory config = helperConfig.getConfig();
        vm.startBroadcast();
        Raffle raffle = new Raffle(
            config.entranceFee,
            config.interval,
            config.vrfCoordinator,
            config.gasLane,
            config.callbackGasLimit,
            config.subscriptionId
        );
        vm.stopBroadcast();
        return (raffle, helperConfig);
    }
}