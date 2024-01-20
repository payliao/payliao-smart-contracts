from functools import wraps
import click
import os
import json
import sys
from web3 import Web3, Account

class deploy_uen_management:
	def __init__(
			self,
			network_rpc: str = "https://rpc-evm-sidechain.xrpl.org",
			sender: str = "0x1465ef7ce4ee81fdef9e854e51b97013c1ff740dfd494ddbbb60176c999f581f", # ALL WATCHES PTE LTD admin account
			instance_address: str = "0x228dfCFf73CcF0a65034aA55621122a5aaD49FE7",
			abi_path: str = "../../abi/uen_management.json",
			limit: int = 200,
			use_sample: bool = True,
			automatic: bool = True,
		):

		with open(abi_path, "r") as f:
			self.abi = json.load(f)["abi"]

		self.web3 = Web3(Web3.HTTPProvider(network_rpc))
		self.instance = self.web3.eth.contract(address=instance_address, abi=self.abi)
		self.automatic = automatic
		self.limit = limit
		self.account = Account.from_key(sender)
		self.use_sample = use_sample
		self.local_uen_list: dict = {}
		self.uen_list_on_contract: list = []

		self.network_check()
		
		if self.use_sample:
			click.echo("Using sample data.")
		
		else:
			click.echo("Using full data.")

		if automatic:
			# Automate the UEN upload process
			self.check_dump_return_list()
			self.get_all_uen()
			self.upload_data()
			self.get_name()

	def upload_data(self, local_uen_list: list = None, uen_list_on_contract: list = None):
		# Defaults
		if local_uen_list is None:
			local_uen_list = self.local_uen_list
		if uen_list_on_contract is None:
			uen_list_on_contract = self.uen_list_on_contract

		if not set(self.local_uen_list.keys()).issubset(set(self.uen_list_on_contract)):
			click.echo("Data is different, updating now.")
			uen_list_to_push = []
			name_list_to_push = []
			count: int = 0
			for a in self.local_uen_list:
				if a not in self.uen_list_on_contract and count < self.limit:
					count += 1
					uen_list_to_push.append(a)
					name_list_to_push.append(self.local_uen_list[a])
			try:

				# Build a transaction
				transaction = self.instance.functions.add_uens(uen_list_to_push, name_list_to_push).build_transaction({
					"value": 0,

					'gas': 2100000000,
					'maxFeePerGas': 10000000000000000000000,
					'maxPriorityFeePerGas': 100000000000000000000,

					"nonce": self.web3.eth.get_transaction_count(self.account.address),
					# "chainId": self.web3.eth.chain_id,
				})

				signed_transaction = self.account.sign_transaction(transaction)
				tx_hash = self.web3.eth.send_raw_transaction(signed_transaction.rawTransaction)
				self.web3.eth.wait_for_transaction_receipt(tx_hash)
				click.echo(f"Transaction sent: {tx_hash.hex()}")

			except KeyboardInterrupt:
				click.echo("Keyboard interrupt detected, stopping the upload process.")
				sys.exit(0)

			except Exception as e:
				self.limit = self.limit // 2 if self.limit // 2 > 0 else 0
				click.echo(f"Error uploading data: {e}\nReducing the limit to {self.limit} and trying again.")
				self.upload_data()
			
			self.uen_list_on_contract = self.get_all_uen()
			click.echo(f"{count} entries added. Continue data update.\nCurrent data count on blockchain: {len(self.uen_list_on_contract)}, total data count on local: {len(self.local_uen_list)}")
			self.limit += 1
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
	
	def get_name(self, limit: int = 10, uen_list: list = None) -> str:
		
		if uen_list is None:
			uen_list = self.uen_list_on_contract

		name_list: dict = {}

		click.echo(f"\nUENs on contract:")
		for b, a in enumerate(uen_list):
			if limit is not None:
				if b > limit:
					break
			name_list[a] = self.instance.get_name(a).call()
			click.echo(f"{a}: {name_list[a]}")
		return name_list

	def get_all_uen(self, uen_list_on_contract: list = None) -> list:
		"""
		Checks if the data has been uploaded to the blockchain.
		"""

		# Defaults
		if uen_list_on_contract is None:
			uen_list = self.uen_list_on_contract
		else:
			uen_list = uen_list_on_contract

		uen_list = self.instance.functions.get_all_uens().call()
		click.echo(f"There are {len(uen_list)} UENs on the blockchain.")
		self.uen_list_on_contract = uen_list if uen_list_on_contract == None else None
		return uen_list

	def network_check(self) -> None:
		chain_id = self.web3.eth.chain_id
		click.echo(f"You are connected to EVM network with ID '{chain_id}'.")

if __name__ == "__main__":
	instance = deploy_uen_management(automatic=False, use_sample=False)
	instance.get_all_uen()