// SPDX-License-Identifier: Proprietary
pragma solidity 0.8.22;

// import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
// import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Iwhitelist {
	/* 
	This interface is used to check if a UEN is onboarded.
	get_uen_to_whitelist gets the whitelisted address for a UEN. UEN is the input.
	*/
	function get_uen_to_whitelist(string memory _uen) external view returns (address);
	function get_whitelist_to_uen(address _whitelist) external view returns (string memory);
}

interface Iuen_management {
	/*
	This interface is used to read the UENs from the UEN management contract. 
	get_name gets the name of the company from the UEN. UEN is the input.
	get_all_uens gets all the UENs from the UEN management contract.
	*/
	function get_name(string memory _uen) external view returns (string memory);
	function get_all_uens() external view returns (string[] memory);
}

contract sgdm is ERC20, Ownable {

	// Contains the ERC20 target token address. This has to be an ERC20. 
	IERC20 public targetToken;

	// Mapping of UEN to amount of tokens they contain. 
	mapping(string => uint256) public uen_to_balance;

	// Contains the list of UEN
	Iuen_management uen_management_contract;

	// Contains the contract of the mapping of the UEN to the whitelisted address. This can also query whitelisted address to UEN.
	Iwhitelist whitelist_contract;

	constructor (address _targetToken, address _uen_management_contract_address, address _initialOwner, address _whitelist_management_contract_address) ERC20 ("SGDm", "SGDm") Ownable(_initialOwner) {
		
		// Specify the token to use
		targetToken = IERC20(_targetToken);

		// UEN management contract
		uen_management_contract = Iuen_management(_uen_management_contract_address);

		// Whitelist management contract
		whitelist_contract = Iwhitelist(_whitelist_management_contract_address);
	}
	
	// Get name of the UEN. This is a public function. If no name exists, break.
	modifier check_name(string memory _uen) {
		require(bytes(uen_management_contract.get_name(_uen)).length > 0, "UEN does not exist");
		_;
	}

	// Function for admins to withdraw tokens from the contract. This is essentially a withdraw function.
	function admin_withdraw(address _to, uint256 _amount) external onlyOwner returns (bool) {
		require(_to != address(0), "Withdraw to the zero address");
		
		uint256 _balance = targetToken.balanceOf(address(this));
		require (_balance >= _amount, "Not enough balance");

		targetToken.transfer(_to, _amount);
		return true;
	}

	// Get name for UEN. This is a public function.
	function get_name(string memory _uen) external view returns (string memory) {
		return uen_management_contract.get_name(_uen);
	}

	// Check if the sender is a whitelisted address. Returns the UEN. 
	function check_whitelist() public view returns (string memory) {
		return whitelist_contract.get_whitelist_to_uen(msg.sender);
	}

	// Balance of UEN
	function balance_of_uen(string memory _uen) external view returns (uint256) {
		return uen_to_balance[_uen];
	}

	/* 
	Send tokens from private wallet to uen. In short, the function that consumers will use. 
	Input: UEN of the company to send tokens to, amount of tokens to send.
	Before sending, ensure that the sender has approved this contract to spend the tokens.
	Before sending, ensure that the UEN exists. 
	After sending, update the mapping of UEN to balance. 
	If there is an associated whitelist address, emit and event to notify the whitelist address of the transfer.
	*/
	function send_token_to_uen(string memory _uen, uint256 _amount) external check_name(_uen) returns (bool) {
		require(bytes(_uen).length > 0, "UEN is empty");
		
		uint256 token_allowance = targetToken.allowance(msg.sender, address(this));
    	require(token_allowance >= _amount, "Increase the allowance");
		
		targetToken.transferFrom(msg.sender, address(this), _amount);
		uen_to_balance[_uen] += _amount;
		
		address _uen_address = whitelist_contract.get_uen_to_whitelist(_uen);
		if (_uen_address != address(0)) {
			emit Transfer(msg.sender, _uen_address, _amount);
		}
		return true;
	}

	/*
	Send tokens between UENs. This is basically an internal transfer function.
	Input: UEN of the company to send tokens to, amount of tokens to send.
	Before sending, ensure that the UEN of the destination exists.
	Before sending, ensure that the spender has enough tokens to send and the spender is the owner of the UEN.
	After sending, if both UENs have an associated whitelist, emit an event to notify both addresses of the transfer.
	*/
	function uen_send(string memory _uen_target, uint256 _amount) external check_name(_uen_target) returns (bool) {
		require(bytes(_uen_target).length > 0, "UEN target is empty");
		string memory _uen_payer = whitelist_contract.get_whitelist_to_uen(msg.sender);
		if (uen_to_balance[_uen_payer] < _amount) {
			return false;
		}
		uen_to_balance[_uen_payer] -= _amount;
		uen_to_balance[_uen_target] += _amount;
		
		address _uen_target_address = whitelist_contract.get_uen_to_whitelist(_uen_target);
		if (_uen_target_address != address(0)) {
			emit Transfer(msg.sender, _uen_target_address, _amount);
		}
		return true;
	}

	/*
	Enable whitelisted addresses to withdraw their tokens to an external address. 
	This is essentially a withdraw function.
	Input: destination address, amount of tokens to withdraw.
	Before sending, ensure that the sender is the whitelisted owner of the UEN. 
	*/
	function transfer(address _to, uint256 _amount) public override returns (bool) {
		require(_to != address(0), "Transfer to zero address");
		string memory _uen_sender = whitelist_contract.get_whitelist_to_uen(msg.sender);
		
		uint256 _balance = uen_to_balance[_uen_sender];
		require (_balance >= _amount, "Not enough balance");
		
		uen_to_balance[_uen_sender] -= _amount;
		emit Transfer(msg.sender, _to, _amount);
		targetToken.transfer(_to, _amount);
		return true;
	}

	// Transfer from, this is an internal transfer function.
	function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
		require(_to != address(0), "Transfer to zero address");
		string memory _uen_sender = whitelist_contract.get_whitelist_to_uen(_from);
		
		uint256 _balance = uen_to_balance[_uen_sender];
		require (_balance >= _amount, "Not enough balance");
		
		uen_to_balance[_uen_sender] -= _amount;
		emit Transfer(_from, _to, _amount);
		targetToken.transfer(_to, _amount);
		return true;
	}

	// Return token address
	function token_address() external view returns (address) {
		return address(targetToken);
	}

	// Decimals
	function decimals() public pure override returns (uint8) {
		return 6;
	}

	// Total supply, returns the token total supply
	function totalSupply() public view override returns (uint256) {
		return uint256(targetToken.totalSupply());
	}

	// Balance of, returns the balance of the UEN which the _owner is associated with.
	// If not associated, it'll return 0.
	function balanceOf(address _owner) public view override returns (uint256 balance) {
		string memory _uen = whitelist_contract.get_whitelist_to_uen(_owner);
		return uen_to_balance[_uen];
	}

	// Function for allowance. This should return the allowance for token.
	function allowance(address _owner, address _spender) public view override returns (uint256) {
		return targetToken.allowance(_owner, _spender);
	}

	// Function for approval. This always return false to prevent anyone from using sgdm.
	function approve(address, uint256) public pure override returns (bool) {
    	revert("Approve function is disabled");
	}
}