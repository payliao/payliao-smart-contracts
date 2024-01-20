// SPDX-License-Identifier: Proprietary

pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {admin_management} from "../src/admin.sol";

contract DeployAdminManagement is Script {
    function run() external returns (address) {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        admin_management adminManagement = new admin_management();
        vm.stopBroadcast();
        return address(adminManagement);
    }
}