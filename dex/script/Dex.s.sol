// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {DexV2Factory} from "src/DexV2Factory.sol";
import {DexV2Router} from "src/DexV2Router.sol";

contract DexFactoryScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new DexV2Factory(msg.sender);
        vm.stopBroadcast();
    }
}

contract DexRouterScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new DexV2Router(
            address(0x5fBE24c79EBCeB20028C275E5798841a67dD4048),
            address(0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889)
        );
        vm.stopBroadcast();
    }
}
