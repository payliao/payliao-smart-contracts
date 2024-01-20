// SPDX-License-Identifier: Proprietary

pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {sgdk} from "../src/sgdk.sol";

contract DeploySgdk is Script {
    function run() external returns (address) {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        sgdk sgdK = new sgdk();
        vm.stopBroadcast();
        return address(sgdK);
    }
}