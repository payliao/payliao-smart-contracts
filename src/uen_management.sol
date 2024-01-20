// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface Iuen_management {
    /* This interface describes the UEN management contract. */
    function get_name(string memory _uen) external view returns (string memory);
    function get_all_uens() external view returns (string[] memory);
    function add_uens(string[] memory _uens, string[] memory _names) external;
    function remove_uens(string[] memory _uens) external;
    function modify_uens(string[] memory _uens, string[] memory _names) external;
}

contract uen_management is Ownable {
    /*
    This contract is used to manage the UENs.
    Refers to the admin management contract to get the list of admins.
    TODO: Add indexed to emitted events.
    */

    // Contains all the UENs.
    string[] public uen_list;

    // Contains the mapping of the UEN to the name of the company.
    mapping(string => string) private uen_to_name;

    // Countains the mapping of the UEN to the index of the UEN in the uen_list.
    mapping(string => uint256) private uen_to_index;

    // Admin list contract address.
    address public admin_list_contract;

    // Contains the list of admins.
    address[] public admins;

    // Add deployer to owner during deployment.
    constructor(address _initialOwner) Ownable(_initialOwner) {

    }

    // Get UEN from the list. This is a public function.
    function get_name(string memory _uen) public view returns (string memory) {
        return uen_to_name[_uen];
    }

    // Get all UENs from the list. This is a public function.
    function get_all_uens() public view returns (string[] memory) {
        return uen_list;
    }

    /* Add UEN and name to the list. This is an admin only function. 
    This accepts 2 arrays as the input, one for the UEN and one for the name. 
    The 2 arrays must have the same length.
    */
    event uen_event(string[] _uens, string _message);

    function add_uens(string[] memory _uens, string[] memory _names) external onlyOwner {
        require(_uens.length == _names.length, "Mappings must have the same length");
        for (uint256 i = 0; i < _uens.length; i++) {
            require(bytes(uen_to_name[_uens[i]]).length == 0, "UEN already exists");
            uen_to_name[_uens[i]] = _names[i];
            uen_list.push(_uens[i]);
            uen_to_index[_uens[i]] = uen_list.length - 1;
        }
        emit uen_event(_uens, "UENs added");
    }

    /* Remove UEN and name from the list. This is an admin only function. 
    This accepts an array of UENs as the input.
    */
    function remove_uens(string[] memory _uens) external onlyOwner {
        for (uint256 i = 0; i < _uens.length; i++) {
            delete uen_to_name[_uens[i]];
            /*
    		Replace the UEN with an empty string since we cannot delete the element from the array as the array will be shifted which will affect the uen_to_index mapping.
            */
            uen_list[uen_to_index[_uens[i]]] = "";
            delete uen_to_index[_uens[i]];
        }
        emit uen_event(_uens, "UENs removed");
    }

    /* Modify UEN name mapping. This is an admin only function. 
    This accepts 2 arrays as the input, one for the UEN and one for the name. 
    The 2 arrays must have the same length. 
    It's recommended to use this function instead of removing and adding the UENs again as 
    the UENs will be shifted in the array which will affect the uen_to_index mapping. 
    It's also recommended to get the UENs from the get_all_uens function and then modify the names to prevent errors.
    */
    function modify_uens(string[] memory _uens, string[] memory _names) external onlyOwner {
        require(_uens.length == _names.length, "Mappings must have the same length");
        for (uint256 i = 0; i < _uens.length; i++) {
            require(bytes(uen_to_name[_uens[i]]).length != 0, "UEN does not exist");
            uen_to_name[_uens[i]] = _names[i];
        }
    }
}