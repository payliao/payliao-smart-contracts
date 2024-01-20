// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.22;

interface Iadmin_management {
    function get_admins() external view returns (address[] memory);
    function add_admins(address[] memory _newAdmins) external;
    function remove_admin(address[] memory _admins) external;
    function remove_admin_by_index(uint256[] memory _indexes) external;
}

contract admin_management {
    /*
    This contract manages the admin list. 
    Used by onboarding which contains the whitelist address for each UEN. 
    Used by uen_management which contains the list of admins that can manage the UENs.
    TODO: Add indexed to emitted events.
    */

    // Contains the list of admins.
    address[] public admins;

    // Add deployer to owner during deployment.
    constructor() {
        admins.push(msg.sender);
    }

    // Check if the caller is an admin. This is a modifier which is called before a function call. This will prevent non-admins from calling the function.
    modifier only_admin() {
        bool is_owner = false;
        for (uint256 i = 0; i < admins.length; i++) {
            if (msg.sender == admins[i]) {
                is_owner = true;
                break;
            }
        }
        require(is_owner, "Only admins can call this function");
        _;
    }

    // Get list of admins. This is a public function.
    function get_admins() public view returns (address[] memory) {
        return admins;
    }

    event admin_event(address[] _admins, string _message);
    // Add new admins to the list. This is an admin only function. This accepts an array of addresses as the input.

    function add_admins(address[] memory _newAdmins) external only_admin {
        for (uint256 i = 0; i < _newAdmins.length; i++) {
            bool alreadyAdmin = false;
            for (uint256 j = 0; j < admins.length; j++) {
                if (_newAdmins[i] == admins[j]) {
                    alreadyAdmin = true;
                    emit admin_event(admins, "Admins already exist");
                    break;
                }
            }
            if (!alreadyAdmin) {
                admins.push(_newAdmins[i]);
                emit admin_event(admins, "Admins added");
            }
        }
    }

    // Remove admins from the list. This is an admin only function. This accepts an array of addresses as the input. The last admin cannot be removed for security reasons.
    function remove_admin(address[] memory _admins) external only_admin {
        require(admins.length > 1, "Cannot remove the last admin");
        for (uint256 i = 0; i < _admins.length; i++) {
            for (uint256 j = 0; j < admins.length; j++) {
                if (_admins[i] == admins[j]) {
                    admins[j] = admins[admins.length - 1];
                    admins.pop();
                    break;
                }
            }
        }
        emit admin_event(admins, "Admins removed");
    }

    // Remove admins from the list by index. This is an admin only function. This accepts an array of indexes as the input. The last admin cannot be removed for security reasons. This function is cheaper in gas compared to removeAdmin.
    function remove_admin_by_index(uint256[] memory _indexes) external only_admin {
        require(admins.length > 1, "Cannot remove the last admin");
        for (uint256 i = 0; i < _indexes.length; i++) {
            require(_indexes[i] < admins.length, "Index out of range");
            admins[_indexes[i]] = admins[admins.length - 1];
            admins.pop();
        }
        emit admin_event(admins, "Admins removed");
    }
}
