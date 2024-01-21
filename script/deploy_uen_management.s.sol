// SPDX-License-Identifier: Proprietary

pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {uen_management} from "../src/uen_management.sol";

contract DeployUenManagement is Script {
    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		vm.startBroadcast(deployerPrivateKey);
        uen_management uenManagement = new uen_management();
        vm.stopBroadcast();
        return address(uenManagement);
    }
}
