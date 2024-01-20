# Overview
The backend contains a few components. They are listed and explained here.
1. Python script
1. Contracts (XRPL EVM)

## Description

There are several Python scripts written. They are designed to grab UEN data from govtech and also to upload these UEN to the blockchain. 

There are 2 helper contracts.
1. admin.sol governs the admins that can manage each contract. This should be deprecated and replaced by the OpenZeppelin's permissions library. 
1. sgdk.sol is a testing stablecoin that should be replaced by an actual stablecoin if deployed as a real project.

There are 3 main contracts. 
1. uen_management.sol contains the list of UEN as well as their names. This is the primary UEN database that exists on the blockchain.
1. whitelist.sol contains the onboarded merchant (UEN) and their wallet address. 
1. sgdm.sol is the primary contract enabling transactions to the QR code. It is an ERC20 compliant contract that merchants can add to their wallet applications. 

## Script
The UEN script is meant to grab the UEN from [data.gov.sg]([data.gov.sg](https://beta.data.gov.sg/collections/2/view)). The parsed files are in the full_uen_filtered_list folder and was parsed as of 24 Oct 2023.

### How to run 
1. Install [Python Poetry](https://python-poetry.org/)
1. Poetry is the package manager. Install this to manage the virtual environment effortlessly. :D
1. Run `poetry update`. This should install all the required dependencies. 
1. Run `poetry shell`

#### Deploy script
1. Run `python3 deploy_uen.py`
   1. The conditions and other settings are already preconfigured. If need be, configure the instance address and the sender. 
      1. Instance address is the address of the uen_management contract.
      1. Sender is the private key of the sender. This sender needs to have admin privilege to upload data to the uen_management contract.

#### UEN Grabber
1. Under construction

## Contracts (XRPL EVM)
* SGDk: `0xa462f79a8c09a0770614140B9f53Ebc9fD8413b5`
* UEN Management (UEN Database): `0x228dfCFf73CcF0a65034aA55621122a5aaD49FE7`
  * Admin Management of UEN Management: `0x0500982F88Cb1d6eDf1F5aa103c1d60938111330`
* Whitelist: `0xeC6a51D2025234A1fd6F81EddC383c17C1c95A21`
  * Admin Management of Whitelist: `0x7ED28E99C8eA2D010d51daEd5526378Fe73A26B1`
* SGDm: `0x1F11B837513dF2F3e17D5b017f83C5c17C76261f`
  * Admin Management of SGDm: `0xD51B80cCA2e8C961f6bEd37882c0570C4891f8f8`

### Contract constructors (under construction)
#### sgdm.sol
* Get name of UEN
  * `function get_name(string memory _uen) external view returns (string memory);`
  * function: get_name
  * input: string uen
  * returns string name

* Get the UEN of sender. This checks if the sender is a whitelisted address of any UEN. 
  * `function check_whitelist() public view returns (string memory);`
  * function: check_whitelist()
  * output: string uen, blank if not a whitelist

* Check allowance of SGDk token
  * `function check_allowance() public view returns (uint256);`
  * function: check_allowance
  * output: allowance of ZEENUS token

* Get SGDk token address
  * `function token_address() external view returns (address);`
  * Call this to get the address of the ZEENUS token (XSGD/USDC/stablecoin)

* Request for allowance of SGDk token. This enables you to pay to this contract. This requires gas.
  * `function approve_token(uint256 _amount) public returns (bool);`
  * function: approve_token
  * input: uint256 amount
  * output: True boolean

* Send SGDk to UEN. Requires allowance so you can pay SGDk tokens to this contract (the bank). This requires gas.
  * `function send_tokens_to_uen(string memory _uen, uint256 _amount) external check_name(_uen) returns (bool);` 
  * function: send_tokens_to_uen
  * input: string uen, uint256 amount
  * output: True for success

* Internal transfer between UENs. Once you (merchant) are onboarded, you can choose to send money to other UENs. This does not require the destination UEN to be onboarded yet (no whitelisted address for the destination UEN). This requires gas. 
  * `function uen_send(string memory _uen_target, uint256 _amount) external check_name(_uen_target) returns (bool);`
  * function: uen_send
  * input: string uen_target, uint256 amount
  * output: True boolean for sucessful transfer

* Transfer SGDk token from bank (this contract) to another address. This functions like a withdrawal function for a whitelisted address. This requires gas.
  * `function transfer(address _to, uint256 _amount) public returns (bool);`
  * function: transfer
  * input: address of payee, uint256 amount
  * output: True boolean for successful transfer

* Balance of UEN. This enables anyone to query the balance of any UEN, including non-onboarded merchants.
  * `function balance_of_uen(string memory _uen) public view returns (uint256);`
  * function: balance_of_uen
  * input: string uen
  * output: uint256 balance

* Balance of whitelisted address. This enables anyone to query the balance of any address. However, it'll only return a value if the address is whitelisted (belongs to a UEN)
  * `function balanceOf(address _owner) public view returns (uint256 balance);` 
  * function: balanceOf
  * input: address to query
  * output: uint256 balance

## TODO
* Add deployment to test net
* Add function to check if govtech data is the latest
* Update the readme properly
* Explain the code properly
* Replace admin contract with proper access control management