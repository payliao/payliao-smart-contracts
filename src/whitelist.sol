// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.22;

interface Iuen_management {
	/*
	This interface is used to read the UENs from the UEN management contract.
	*/
	function get_name(string memory _uen) external view returns (string memory);
	function get_all_uens() external view returns (string[] memory);
}

interface Iadmin_management {
	function get_admins() external view returns (address[] memory);
}

interface Iwhitelist {
	/*
	This interface describes all the function in the whitelist contract.
	*/
	function get_uen_to_whitelist(string memory _uen) external view returns (address);
	function get_whitelist_to_uen(address _whitelist) external view returns (string memory);
	function get_admins() external view returns (address[] memory);
	function change_admin_list_contract_address(address _new_admin_list_contract_address) external;
	function change_uen_list_contract_address(address _new_uen_list_contract_address) external;
	function map_whitelist_to_uen(string[] memory _uens, address[] memory _admins) external;
	function remove_whitelist_to_uen_mapping(string[] memory _uens) external;
}

contract whitelist {
	/*
	This contract enables merchants to onboard for withdrawal.
	This refers to 2 other contracts, one for the list of UENs, and another for the list of admins that can control the onboarding process in this contract.
	The admin can add a whitelisted address to a specific UENs, and only that address can withdraw for that UEN.
	TODO: Add indexed to emitted events.
	TODO: Replace admin contract with a proper access control contract.
	*/

	// Address of the UEN management contract.
	address public uen_management_contract_address;
	// Interface of the UEN management contract.
	Iuen_management public uen_management_contract;

	// Address of the admin management contract.
	address public admin_management_contract_address;
	// Interface of the admin management contract.
	Iadmin_management public admin_management_contract;

	// List of UENs
	string[] public uen_list;

	// Contains the list of admins.
	address[] public admins;

	// Contains the UEN to whitelist mapping
	/* 
	NOTE: If more than 1 whitelist is required for a UEN, 
	then this mapping should be changed to a multisig contract to manage that UEN.
	*/
	mapping(string => address) public uen_to_whitelist;

	// We need a whitelist to UEN mapping as well to comply with ERC20 standard.
	mapping (address => string) public whitelist_to_uen;

	constructor (address _uen_management_contract_address, address _admin_management_contract_address) {
		/*
		Constructor: 
		Set the UEN management contract address.
		Get all the UENs from the UEN management contract.

		Set the admin management contract address.
		Get all the admins from the admin management contract.
		*/
		uen_management_contract_address = _uen_management_contract_address;
		uen_management_contract = Iuen_management(_uen_management_contract_address);
		uen_list = uen_management_contract.get_all_uens();

		admin_management_contract_address = _admin_management_contract_address;
		admin_management_contract = Iadmin_management(_admin_management_contract_address);
		admins = admin_management_contract.get_admins();
	}

	// Update the uen_list everytime a function is called. This is a modifier which is called before a function call.
	modifier update_uen_list_and_check_uen() {
		uen_list = uen_management_contract.get_all_uens();
		_;
	}

	// Update the admin list everytime a function is called. This is a modifier which is called before a function call.
	modifier update_admin_list() {
		admins = admin_management_contract.get_admins();
		_;
	}

	// Check if the caller is an admin. This is a modifier which is called before a function call. This will prevent non-admins from calling the function.
	modifier only_admin() {
		bool is_owner = false;
		for (uint i = 0; i < admins.length; i++) {
			if (msg.sender == admins[i]) {
				is_owner = true;
				break;
			}
		}
		require(is_owner, "Only admins can call this function");
		_;
	}

	// Returns the UEN to admin mapping. This is a public function.
	function get_uen_to_whitelist(string memory _uen) public view returns (address) {
		return uen_to_whitelist[_uen];
	}

	// Returns the whitelist to UEN mapping. This is a public function.
	function get_whitelist_to_uen(address _whitelist) public view returns (string memory) {
		return whitelist_to_uen[_whitelist];
	}

	// Get list of admins. This is a public function.
	function get_admins() public view returns (address[] memory) {
		return admins;
	}

	// Change admin list contract address. This is an admin only function. This accepts the new address as the input.
	// Two functions are called before the mapping is done:
	// 1. update_admin_list, which updates the admin list.
	// 2. only_admin, which checks if the caller is an admin.
	function change_admin_list_contract_address(address _new_admin_list_contract_address) external update_admin_list only_admin {
		admin_management_contract_address = _new_admin_list_contract_address;
		admin_management_contract = Iadmin_management(_new_admin_list_contract_address);
		admins = admin_management_contract.get_admins();
	}

	// Change UEN list contract address. This is an admin only function. This accepts the new address as the input.
	// Two functions are called before the mapping is done:
	// 1. update_admin_list, which updates the admin list.
	// 2. only_admin, which checks if the caller is an admin.
	function change_uen_list_contract_address(address _new_uen_list_contract_address) external update_admin_list only_admin {
		uen_management_contract_address = _new_uen_list_contract_address;
		uen_management_contract = Iuen_management(_new_uen_list_contract_address);
		uen_list = uen_management_contract.get_all_uens();
	}

	/* Map whitelists to a UEN. This is an admin only function. 
	This accepts 2 arrays as the input, one for the UEN and one for the admin. 
	The 2 arrays must have the same length. 
	This also checks if the UEN exists in the UEN management contract.
	Three functions are called before the mapping is done: 
	1. update_admin_list, which updates the admin list.
	2. only_admin, which checks if the caller is an admin.
	3. update_uen_list_and_check_uen, which updates the UEN list and checks if the UEN exists in the UEN management contract.
	*/
	event whitelist_event(string[] _uens, uint _timestamp, address _caller, string _action);
	function map_whitelist_to_uen(string[] memory _uens, address[] memory _admins) external update_admin_list only_admin update_uen_list_and_check_uen {
		require(_uens.length == _admins.length, "Mappings must have the same length");
		for (uint i = 0; i < _uens.length; i++) {
			bool uen_exists = false;
			for (uint j = 0; j < uen_list.length; j++) {
				if (keccak256(abi.encodePacked(_uens[i])) == keccak256(abi.encodePacked(uen_list[j]))) {
					uen_exists = true;
					break;
				}
			}
			require(uen_exists, "UEN does not exist");
			uen_to_whitelist[_uens[i]] = _admins[i];
			whitelist_to_uen[_admins[i]] = _uens[i];
		}
		emit whitelist_event(_uens, block.timestamp, msg.sender, "Whitelist added for UEN");
	}

	/* Removes the UEN to admin mapping. This is an admin only function. This accepts an array of UENs as the input.
	Three functions are called before the mapping is done: 
	1. update_admin_list, which updates the admin list.
	2. only_admin, which checks if the caller is an admin.
	3. update_uen_list_and_check_uen, which updates the UEN list and checks if the UEN exists in the UEN management contract.
	*/
	function remove_whitelist_to_uen_mapping(string[] memory _uens) external update_admin_list only_admin update_uen_list_and_check_uen {
		for (uint i = 0; i < _uens.length; i++) {
			delete uen_to_whitelist[_uens[i]];
			delete whitelist_to_uen[uen_to_whitelist[_uens[i]]];
		}
		emit whitelist_event(_uens, block.timestamp, msg.sender, "Whitelist removed for UEN");
	}
}