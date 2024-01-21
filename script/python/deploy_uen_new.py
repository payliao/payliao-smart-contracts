import click
import os
import json
import sys
from web3 import Web3, Account


class deploy_uen_management:
	def __init__(
			self,
			# network_rpc: str = os.environ.get("SEPOLIA_RPC_URL"),
			network_rpc: str = os.environ.get("MUMBAI_RPC_URL"), 
			sender: str = os.environ.get("PRIVATE_KEY"), # AGZ FOOD PTE LTD admin account
			# instance_address: str = "0x2a3c31365C4270355FF372311bE25F1cBB39129c", # Sepolia
			instance_address: str = "0xcF20d9947590E7d8Fc62d1ca0ea775Ee5bC5faF9", # Mumbai
			abi_path: str = "../../abi/uen_management.json",
			limit: int = 200,
			use_sample: bool = True,
			automatic: bool = True,
		):

		self.network_rpc = os.environ.get("MUMBAI_RPC_URL")
		self.network_rpc = os.environ.get("MUMBAI_RPC_URL_2")
		self.sender = sender

		with open(abi_path, "r") as f:
			self.abi = json.load(f)["abi"]

		self.web3 = Web3(Web3.HTTPProvider(self.network_rpc))
		self.instance = self.web3.eth.contract(address=instance_address, abi=self.abi)
		self.automatic = automatic
		self.limit = limit
		self.account = Account.from_key(self.sender)
		self.use_sample = use_sample
		
		self.uen_list_contract_length: int = 0
		self.local_uen_list: dict = {}
		self.uen_list_on_contract: list = []
		self.prev_uen: str = ""
		self.gas = 100000000
		self.prev_transaction = ""

		self.network_check()
		click.echo("Using account: " + self.account.address)
		
		if self.use_sample:
			click.echo("Using sample data.")
		
		else:
			click.echo("Using full data.")

		if automatic:
			# Automate the UEN upload process
			self.check_dump_return_list()
			self.get_uen_list_length_on_contract()
			self.get_uen()
			self.upload_data()

	def get_uen_list_length_on_contract(self) -> int:
		"""
		Returns the length of the UEN list on the contract.
		"""
		self.uen_list_contract_length = self.instance.functions.get_uen_list_length().call()
		click.echo("Total UEN list length on contract: " + str(self.uen_list_contract_length))
		return self.uen_list_contract_length

	def upload_data(self, local_uen_list: list = None, uen_list_on_contract: list = None):
		# Defaults
		if local_uen_list is None:
			local_uen_list = self.local_uen_list
		if uen_list_on_contract is None:
			uen_list_on_contract = self.uen_list_on_contract

		if not set(self.local_uen_list.keys()).issubset(set(self.uen_list_on_contract)):
			click.echo("Data is different, checking the differences and updating now.")
			uen_list_to_push = []
			name_list_to_push = []

			count: int = 0
			if self.uen_list_contract_length >= 20:
				for a in list(self.local_uen_list.keys())[len(self.uen_list_on_contract) - 10:]:
					if a not in self.uen_list_on_contract[-20:] and count < self.limit:
						count += 1
						uen_list_to_push.append(a)
						name_list_to_push.append(self.local_uen_list[a])
			
			# If the contract is empty
			else:
				for a in self.local_uen_list.keys():
					if a not in self.uen_list_on_contract and count < self.limit:
						count += 1
						uen_list_to_push.append(a)
						name_list_to_push.append(self.local_uen_list[a])

			# Check to make sure that the first UEN is not the same as the previous one. If so, that means that the previous transaction has failed and we need to reduce the limit.
			if uen_list_to_push[0] == self.prev_uen:
				self.limit = int(0.9 * self.limit) if self.limit >= 1 else 1
				uen_list_to_push = uen_list_to_push[: int (0.9 * self.limit)]
				name_list_to_push = name_list_to_push[: int (0.9 * self.limit)]
				click.echo(f"First UEN is the same as the previous one, reducing the limit to {self.limit} and trying again.")

			self.prev_uen = uen_list_to_push[0]
			click.echo(f"Pushing {self.limit} entries to the blockchain.")
			try:

				# Build a transaction
				transaction = self.instance.functions.add_uens(uen_list_to_push, name_list_to_push).build_transaction({
					"from": self.account.address,
					"value": 0,
					'gas': self.gas, #100000000,
					'maxFeePerGas': 100000000000,
					'maxPriorityFeePerGas': 10000000000,
					"nonce": self.web3.eth.get_transaction_count(self.account.address),
					"chainId": self.web3.eth.chain_id,
				})
				
				click.echo("Nonce: " + str(transaction["nonce"]))
				click.echo("First UEN: " + str(uen_list_to_push[0]) + " First name: " + str(name_list_to_push[0]))
				click.echo("Last UEN: " + str(uen_list_to_push[-1]) + " Last name: " + str(name_list_to_push[-1]))

				signed_transaction = self.account.sign_transaction(transaction)
				tx_hash = self.web3.eth.send_raw_transaction(signed_transaction.rawTransaction)
				click.echo(f"Transaction pending: {tx_hash.hex()}")
				self.web3.eth.wait_for_transaction_receipt(tx_hash)
				click.echo(f"Transaction succeeded")

			except KeyboardInterrupt:
				click.echo("Keyboard interrupt detected, stopping the upload process.")
				sys.exit(0)

			except ValueError as e:
				click.echo("Value error detected, raising gas price by 10% and trying again.")
				self.gas = int(1.1 * self.gas) + 1

			except Exception as e:
				self.gas = 100000000
				self.limit = int(0.9 * self.limit) if self.limit >= 1 else 1
				click.echo(f"Error uploading data: {e}\nReducing the limit to {self.limit} and trying again.")
				self.upload_data()
			
			# Update the data
			self.get_uen_list_length_on_contract()
			
			# Get the last 20 UENs on the contract
			self.uen_list_on_contract = self.get_uen(start_index=self.uen_list_contract_length - 21, end_index=self.uen_list_contract_length - 1)
			click.echo(f"{count} entries added. Continue data update.\nCurrent data count on blockchain: {self.uen_list_contract_length}, total data count on local: {len(self.local_uen_list)}")

			self.limit += int(0.01 * self.limit)
			self.upload_data()
		else:
			click.echo(f"Data is the same. Total data on both blockchain and local: {len(self.uen_list_on_contract)}")

	def check_dump_return_list(self, path: str = "uen_data/full_uen_filtered_list/", local_uen_list: dict = None) -> dict:
		"""
		Checks if the data has been dumped.
		"""

		# Defaults
		if local_uen_list is None:
			local_uen_list = self.local_uen_list

		if self.use_sample:
			path: str = "uen_data/sample/"

		if not os.path.exists(path=path):
			click.echo("Data has not been dumped. Dump the data from SG Gov first!")
		else:
			click.echo("Data exists, extracting the data.")
		
		for i in os.listdir(path=path):
			click.echo(f"Found {i} in {path}" + ("\n" if self.use_sample else ""))
			try:
				with open(path + i, "r") as f:
					# Load the file
					data = json.load(f)
					for a in data:
						local_uen_list[a["uen"]] = a["entity_name"]
						click.echo(f"{a['uen']}: {a['entity_name']}") if self.use_sample else None
			except:
				click.echo(f"Error opening {i} folder, skipping...")
				continue
		
		click.echo(f"\nFound {len(local_uen_list)} UENs in total.")
		return local_uen_list

	def get_uen(self, uen_list_on_contract: list = None, start_index: int = 0, end_index: int = 0) -> list:
		"""
		Checks if the data has been uploaded to the blockchain.
		"""

		# Defaults
		if uen_list_on_contract is None:
			uen_list = self.uen_list_on_contract
		else:
			uen_list = uen_list_on_contract
		if end_index == 0 or self.uen_list_contract_length == 0:
			click.echo("\nThere are no UENs on the blockchain.")
			return []

		uen_list = self.instance.functions.get_all_uens(start_index, end_index).call()
		click.echo(f"\nFetched {len(uen_list)} UENs from the contract.")
		self.uen_list_on_contract = uen_list if uen_list_on_contract == None else None
		return uen_list

	def network_check(self) -> None:
		chain_id = self.web3.eth.chain_id
		click.echo(f"You are connected to EVM network with ID '{chain_id}'.")

if __name__ == "__main__":
	instance = deploy_uen_management(automatic=True, use_sample=False)