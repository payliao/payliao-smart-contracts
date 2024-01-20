// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.22;

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
