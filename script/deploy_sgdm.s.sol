// SPDX-License-Identifier: Proprietary

pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {sgdm} from "../src/sgdm.sol";

contract DeploySgdm is Script {
    function run() external returns (address) {
		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        sgdm sgdM = new sgdm(0xa462f79a8c09a0770614140B9f53Ebc9fD8413b5, 0x228dfCFf73CcF0a65034aA55621122a5aaD49FE7, 0xD51B80cCA2e8C961f6bEd37882c0570C4891f8f8, 0xeC6a51D2025234A1fd6F81EddC383c17C1c95A21);
        vm.stopBroadcast();
        return address(sgdM);
    }
}