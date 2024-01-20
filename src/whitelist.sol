// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface Iuen_management {
	/*
	This interface is used to read the UENs from the UEN management contract.
	*/
	function get_name(string memory _uen) external view returns (string memory);
}

interface Iwhitelist {
	/*
	This interface describes all the function in the whitelist contract.
	*/
	function get_uen_to_whitelist(string memory _uen) external view returns (address);
	function get_whitelist_to_uen(address _whitelist) external view returns (string memory);
	function change_uen_list_contract_address(address _new_uen_list_contract_address) external;
	function map_whitelist_to_uen(string[] memory _uens, address[] memory _admins) external;
	function remove_whitelist_to_uen_mapping(string[] memory _uens) external;
}

contract whitelist is Ownable{
	/*
	This contract enables merchants to onboard for withdrawal.
	This refers to 2 other contracts, one for the list of UENs, and another for the list of admins that can control the onboarding process in this contract.
	The admin can add a whitelisted address to a specific UENs, and only that address can withdraw for that UEN.
	TODO: Add indexed to emitted events.
	*/

	// Interface of the UEN management contract.
	Iuen_management public uen_management_contract;

	// Contains the UEN to whitelist mapping
	/* 
	NOTE: If more than 1 whitelist is required for a UEN, 
	then this mapping should be changed to a multisig contract to manage that UEN.
	*/
	mapping(string => address) public uen_to_whitelist;

	// We need a whitelist to UEN mapping as well to comply with ERC20 standard.
	mapping (address => string) public whitelist_to_uen;

	constructor (address _uen_management_contract_address, address _initialOwner) Ownable(_initialOwner) {
		/*
		Constructor: 
		Set the UEN management contract address.
		*/
		uen_management_contract = Iuen_management(_uen_management_contract_address);
	}

	// Returns the UEN to admin mapping. This is a public function.
	function get_uen_to_whitelist(string memory _uen) public view returns (address) {
		return uen_to_whitelist[_uen];
	}

	// Returns the whitelist to UEN mapping. This is a public function.
	function get_whitelist_to_uen(address _whitelist) public view returns (string memory) {
		return whitelist_to_uen[_whitelist];
	}

	// Change UEN list contract address. This is an onlyOwner function. This accepts the new address as the input.
	// These functions are called before the mapping is done:
	// 1. onlyOwner, which checks if the caller is an admin.
	function change_uen_list_contract_address(address _new_uen_list_contract_address) external onlyOwner {
		uen_management_contract = Iuen_management(_new_uen_list_contract_address);
	}

	/* Map whitelists to a UEN. This is an onlyOwner function. 
	This accepts 3 arrays as the input, one for the UEN, names and the admins.
	UEN and names are there to check if the UEN exists and the name matches.
	The 3 arrays must have the same length. 

	These functions are called before the mapping is done: 
	1. onlyOwner, which checks if the caller is an admin.
	*/
	event whitelist_event(string[] _uens, string[] _names, uint _timestamp, address _caller, string _action);
	function map_whitelist_to_uen(string[] memory _uens, string[] memory _names, address[] memory _admins) external onlyOwner {
    	require(_uens.length == _admins.length && _uens.length == _names.length, "All inputs must have the same length");
		for (uint i = 0; i < _uens.length; i++) {
			string memory name = uen_management_contract.get_name(_uens[i]);
			require(bytes(name).length > 0, "UEN does not exist");
			require(keccak256(abi.encodePacked(name)) == keccak256(abi.encodePacked(_names[i])), "Name does not match");
			uen_to_whitelist[_uens[i]] = _admins[i];
			whitelist_to_uen[_admins[i]] = _uens[i];
		}
		emit whitelist_event(_uens, _names, block.timestamp, msg.sender, "Whitelist added for UEN");
	}

	/* Removes the UEN to admin mapping. This is an onlyOwner function. 
	This accepts 3 arrays as the input, one for the UEN, names and the admins.
	UEN and names are there to check if the UEN exists and the name matches.
	The admins are also there to ensure that the admin is the one added to the mapping.
	The 3 arrays must have the same length.

	These functions are called before the mapping is done: 
	1. onlyOwner, which checks if the caller is an admin.
	*/
	function remove_whitelist_to_uen_mapping(string[] memory _uens, string[] memory _names, address[] memory _admins) external onlyOwner {
		require (_uens.length == _admins.length && _uens.length == _names.length, "All inputs must have the same length");
		for (uint i = 0; i < _uens.length; i++) {
			require(keccak256(abi.encodePacked(uen_management_contract.get_name(_uens[i]))) == keccak256(abi.encodePacked(_names[i])), "Name does not match");
			require(uen_to_whitelist[_uens[i]] == _admins[i], "Whitelist does not exist");
			delete uen_to_whitelist[_uens[i]];
			delete whitelist_to_uen[uen_to_whitelist[_uens[i]]];
		}
		emit whitelist_event(_uens, _names, block.timestamp, msg.sender, "Whitelist removed for UEN");
	}
}