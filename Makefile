-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil 

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

help:
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network xrpl\""
	@echo "Usage:"
	@echo "  make deploy [ARGS=...]\n    example: make deploy ARGS=\"--network sepolia\""

all: clean remove install update build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install openzeppelin/openzeppelin-contracts --no-commit

# Update Dependencies
update:; forge update

build:; forge build --skip /Users/xueyao/Documents/sgqr/payliao/payliao-smart-contracts/script/python/.venv/lib/python3.10/site-packages/ethpm/ethpm-spec/examples/wallet-with-send/contracts/WalletWithSend.sol /Users/xueyao/Documents/sgqr/payliao/payliao-smart-contracts/script/python/.venv/lib/python3.10/site-packages/ethpm/ethpm-spec/examples/wallet/contracts/Wallet.sol /Users/xueyao/Documents/sgqr/payliao/payliao-smart-contracts/script/python/.venv/lib/python3.10/site-packages/ethpm/ethpm-spec/examples/transferable/contracts/Transferable.sol /Users/xueyao/Documents/sgqr/payliao/payliao-smart-contracts/script/python/.venv/lib/python3.10/site-packages/ethpm/ethpm-spec/examples/wallet/contracts/Wallet.sol script/python

test :; forge test 

coverage :; forge coverage --report debug > coverage-report.txt

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

NETWORK_ARGS := --rpc-url http://localhost:8545 --private-key $(DEFAULT_ANVIL_KEY) --broadcast

ifeq ($(findstring --network mumbai,$(ARGS)),--network mumbai)
	NETWORK_ARGS := --rpc-url $(MUMBAI_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast
endif

ifeq ($(findstring --network polygon,$(ARGS)),--network polygon)
	NETWORK_ARGS := --rpc-url $(POLYGON_MAINNET_RPC_URL) --private-key $(PRIVATE_KEY) --broadcast
endif

deployAdmin:
	@forge script script/deploy_admin.s.sol:DeployAdminManagement $(NETWORK_ARGS)

deployUEN:
	@forge script script/deploy_admin.s.sol:DeployUenManagement $(NETWORK_ARGS)

deployWhitelist:
	@forge script script/deploy_admin.s.sol:DeployWhitelist $(NETWORK_ARGS)

deploySgdm:
	@forge script script/deploy_admin.s.sol:DeploySgdm $(NETWORK_ARGS)