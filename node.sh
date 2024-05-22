#!/bin/bash


CHAINID="volley_9981-9981"
MONIKER="validator2"
# Remember to change to other types of keyring like 'file' in-case exposing to outside world,
# otherwise your balance will be wiped quickly
# The keyring test does not require private key to steal tokens from you
LOGLEVEL="info"
# Set dedicated home directory for the v2xd instance
HOMEDIR="$HOME/.v2xd"
# to trace evm
#TRACE="--trace"
TRACE=""
MAINNODE_RPC="http://54.153.41.123:26657"
MAINNODE_ID="c29bf2fc6da9eef8cfcba47940a4c82a1d0a80be@54.153.41.123:26656"
# Path variables
CONFIG=$HOMEDIR/config/config.toml
GENESIS=$HOMEDIR/config/genesis.json
TMP_GENESIS=$HOMEDIR/config/tmp_genesis.json

# validate dependencies are installed


# User prompt if an existing local node configuration is found.
if [ -d "$HOMEDIR" ]; then
	printf "\nAn existing folder at '%s' was found. You can choose to delete this folder and start a new local node with new keys from genesis. When declined, the existing local node is started. \n" "$HOMEDIR"
	echo "Overwrite the existing configuration and start a new local node? [y/n]"
	read -r overwrite
else
	overwrite="Y"
fi

# Setup local node if overwrite is set to Yes, otherwise skip setup
if [[ $overwrite == "y" || $overwrite == "Y" ]]; then
	# Remove the previous folder
	rm -rf "$HOMEDIR"
	# cp -r v2xd /usr/bin/
	# Set client config
	# Set moniker and chain-id for Evmos (Moniker can be anything, chain-id must be an integer)
	v2xd init $MONIKER -o --chain-id $CHAINID --home "$HOMEDIR"
    curl $MAINNODE_RPC/genesis? | jq ".result.genesis" > ~/.v2xd/config/genesis.json
    # set seed to main node's id manually
    sed -i 's/seeds = ""/seeds = "'$MAINNODE_ID'"/g' ~/.v2xd/config/config.toml
	if [[ $1 == "pending" ]]; then
		if [[ "$OSTYPE" == "darwin"* ]]; then
			sed -i '' 's/timeout_propose = "3s"/timeout_propose = "30s"/g' "$CONFIG"
			sed -i '' 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' "$CONFIG"
			sed -i '' 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' "$CONFIG"
			sed -i '' 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' "$CONFIG"
			sed -i '' 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' "$CONFIG"
			sed -i '' 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' "$CONFIG"
			sed -i '' 's/timeout_commit = "3s"/timeout_commit = "150s"/g' "$CONFIG"
			sed -i '' 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' "$CONFIG"
		else
			sed -i 's/timeout_propose = "3s"/timeout_propose = "30s"/g' "$CONFIG"
			sed -i 's/timeout_propose_delta = "500ms"/timeout_propose_delta = "5s"/g' "$CONFIG"
			sed -i 's/timeout_prevote = "1s"/timeout_prevote = "10s"/g' "$CONFIG"
			sed -i 's/timeout_prevote_delta = "500ms"/timeout_prevote_delta = "5s"/g' "$CONFIG"
			sed -i 's/timeout_precommit = "1s"/timeout_precommit = "10s"/g' "$CONFIG"
			sed -i 's/timeout_precommit_delta = "500ms"/timeout_precommit_delta = "5s"/g' "$CONFIG"
			sed -i 's/timeout_commit = "3s"/timeout_commit = "150s"/g' "$CONFIG"
			sed -i 's/timeout_broadcast_tx_commit = "10s"/timeout_broadcast_tx_commit = "150s"/g' "$CONFIG"
		fi
	fi

	sed -i 's/timeout_commit = "5s"/timeout_commit = "3s"/g' "$CONFIG"
	sed -i 's/cors_allowed_origins = \[\]/cors_allowed_origins = \["*"\]/g' "$CONFIG"
	sed -i 's/laddr = "tcp:\/\/127.0.0.1:26657"/laddr = "tcp:\/\/0.0.0.0:26657"/g' "$CONFIG"

	sed -i 's/address = "127.0.0.1:8545"/address = "0.0.0.0:8545"/g' ~/.v2xd/config/app.toml
	sed -i 's/ws-address = "127.0.0.1:8546"/ws-address = "0.0.0.0:8546"/g' ~/.v2xd/config/app.toml
	
	sed -i '/\[api\]/,+3 s/enable = false/enable = true/' ~/.v2xd/config/app.toml
	sed -i 's/swagger = false/swagger = true/g' ~/.v2xd/config/app.toml
	sed -i 's/enabled-unsafe-cors = false/enabled-unsafe-cors = true/g'  ~/.v2xd/config/app.toml
	# sed -i 's/enable-indexer = false/enable-indexer = true/g' ~/.v2xd/config/app.toml
	sed -i 's/api = "eth,net,web3"/api = "eth,txpool,personal,net,debug,web3,pubsub,trace"/g' ~/.v2xd/config/app.toml
	sed -i 's/pruning = "default"/pruning = "nothing"/g' ~/.v2xd/config/app.toml

	# Allocate genesis accounts (cosmos formatted addresses)
	
	
	# Run this to ensure everything worked and that the genesis file is setup correctly
	v2xd validate-genesis --home "$HOMEDIR"

	if [[ $1 == "pending" ]]; then
		echo "pending mode is on, please wait for the first block committed."
	fi
fi

v2xd start --pruning=nothing "$TRACE"  --minimum-gas-prices=0.0001av2x --rpc.laddr tcp://0.0.0.0:26657 --log_level $LOGLEVEL --json-rpc.api eth,txpool,personal,net,debug,web3 --api.enable --home "$HOMEDIR"

# v2xd start --pruning=nothing "$TRACE"  --rpc.laddr tcp://0.0.0.0:26657 --log_level $LOGLEVEL --json-rpc.api eth,txpool,personal,net,debug,web3 --api.enable --home "$HOMEDIR"