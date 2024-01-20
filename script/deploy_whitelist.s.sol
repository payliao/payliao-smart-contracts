// SPDX-License-Identifier: Proprietary

pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {whitelist} from "../src/whitelist.sol";

contract DeployWhitelist is Script {
    function run() external returns (address) {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        whitelist whiteList = new whitelist(0x228dfCFf73CcF0a65034aA55621122a5aaD49FE7, 0x7ED28E99C8eA2D010d51daEd5526378Fe73A26B1);
        vm.stopBroadcast();
        return address(whiteList);
    }
}