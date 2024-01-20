import requests
import json
import time
from web3 import Web3

class uen_grabber:
	base_url = "https://api-production.data.gov.sg"
	acra_uen_collection_id = 2
	increment = 20000

	def __init__(self):
		pass

	def get_collection_metadata(self, id: int = acra_uen_collection_id, full: bool = False) -> dict: # Defaults to 2, which is the ACRA UEN collection
		'''
		Parameters:
			id: int
				The collection ID to get the metadata from
			full: bool
				Whether to return the full output or just the child datasets
		Returns:
			dict
				The full output if full is true, otherwise just the child datasets
		This function grabs the collection metadata from the given collection ID. Defaults to the ACRA UEN collection which is 2.
		'''
		# Added a sleep here to prevent rate limiting
		time.sleep(1)
		# Get the full URL
		url = self.base_url + f"/v2/public/api/collections/{id}/metadata"
		# Make the request
		result = self._get(url=url, params=None, headers=None)
		# If full is false, return the child datasets, otherwise return the full output
		if not full:
			try:
				# Check if the child datasets are empty or if the first element is not a dataset
				if result["data"]["collectionMetadata"]["childDatasets"] is None or result["data"]["collectionMetadata"]["childDatasets"][0][0] != "d":
					raise Exception("Issues with child dataset, check data by printing results or pipe to external file")
				return result["data"]["collectionMetadata"]["childDatasets"]
			# If there are issues, print the error and return the full output
			except Exception as e:
				print(f"Error with printing child datasets, check result\n{e}")
				return result
		else:
			return result
	
	def get_dataset_metadata(self, id: int) -> dict:
		'''
		Parameters:
			id: int
				The dataset ID to get the metadata from
		Returns:
			dict
				The full output
		
		This function grabs the dataset metadata from the given dataset ID. Dataset ID usually starts with 'd'.
		'''
		# Added a sleep here to prevent rate limiting
		time.sleep(1)
		# Get the full URL
		url = self.base_url + f"/v2/public/api/datasets/{id}/metadata"
		# Make the request
		result = self._get(url=url, params=None, headers=None)
		return result
	
	def datastore_search(self, params: dict) -> dict:
		'''
		Parameters:
			params: dict
				The parameters to pass to the datastore_search API
		Returns:
			dict
				The full output
		This function grabs the data from the datastore_search API. The parameters are passed in as a dictionary. Returns the full output. If resource_id is not in the params, defaults to the ACRA UEN collection ID which is 2.
		'''
		# Added a sleep here to prevent rate limiting
		time.sleep(1)
		# url = self.base_url + f"/v2/public/api/action/datastore_search" # This is supposed to be v2, but it seems it's not online yet. Using v1 for now. 
		url = "https://data.gov.sg/api/action/datastore_search"
		# If resource_id is not in the params, defaults to the ACRA UEN collection ID which is 2. 
		if "resource_id" not in params:
			params["resource_id"] = self.acra_uen_collection_id
		# Make the request
		result = self._get(url=url, params=params, headers=None)
		return result
	
	def full_data_dump(self, id: int = acra_uen_collection_id):
		'''
		Parameters:
			id: int
				The collection ID to get the child datasets from
		Returns:
			None
		This function grabs the child datasets from the given collection ID. Defaults to the ACRA UEN collection which is 2. Then it goes through each child dataset and grabs the data from the datastore_search API. The data is then written to a file with the child dataset name.
		'''
		# Get the child datasets
		child_datasets = self.get_collection_metadata(id=id)
		# Go through all the child datasets
		for i in child_datasets:
			print(f"\nStarting to parse {i} child dataset")
			# Count the number of records. Resets for every new child dataset
			count: int = 0
			# The full list of records for each child dataset. Resets for each new child dataset
			full_list: list = []
			
			# Keep going until there are no more records
			while True:
				params = {
					"resource_id": i, # The child dataset ID
					"fields": "uen, entity_name, entity_status_description", # The fields to return
					"limit": self.increment,
					"offset": count
				}
				
				# Make the request
				output: list = self.datastore_search(params=params)

				# If there are no more records, break out of the loop and write the results to a file with the child dataset name
				if len(output["result"]["records"]) == 0:
					print(f"Finished parsing {i} child dataset")
					uen_grabber.result_to_json(result=full_list, output_file=i, mode="w")
					break
				
				# If there are records, append them to the full list
				output = output["result"]["records"]
				# Filter out the records that are not live or na. Live and na are usually live companies.
				for j in output:
					if j["entity_status_description"] == "na" or j["entity_status_description"] == "Live":
						full_list.append(j)
				print(f"Finished parsing {count + self.increment} records from {i} child dataset")
				# Increment the counter
				count += self.increment

	@staticmethod
	def result_to_json(result: dict, output_file: str, mode: str = "w") -> bool:
		'''
		Parameters:
			result: dict
				The result to write to file
			output_file: str
				The output file name
			mode: str
				The mode to write to file. Defaults to "w"
		This function writes the result to a file with the given output file name. Defaults to "w" mode. Returns True if successful, False otherwise.
		'''
		if result == None:
			print ("No results to write to file, either due to an error or no results")
			return False
		try:
			with open(output_file, mode) as outfile:
				outfile.write(json.dumps(result, indent=4))
		except Exception as e:
			print(f"Error with writing to file: {e}")

	@staticmethod
	def _get(url, params=None, headers=None):
		""" Implements a get request """
		try:
			response = requests.get(url, params=params, headers=headers)
			payload = response.json()
			response.raise_for_status()
		except requests.exceptions.ConnectionError as e:
			raise Exception (f"HTTP Error: {url}, {e.response.status_code}")
		except requests.exceptions.HTTPError as e:
			code = e.response.status_code
			if code == 429: 
				raise Exception (f"HTTPError {code}, rate limited\n{url}\n{payload['code']}: {payload['message']}")
			if code == 400:
				raise Exception (f"HTTPError {code}, bad request\n{url}\n{payload['code']}: {payload['message']}")
			if code == 422:
				raise Exception (f"HTTPError {code}, unprocessable entity\n{url}\n{payload['code']}: {payload['message']}")
			payload = {"error": e}
		return payload

if __name__ == "__main__":
	uen_grabber = uen_grabber()
	uen_grabber.full_data_dump()