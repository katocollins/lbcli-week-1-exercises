#!/bin/bash
ADDR=$(bitcoin-cli -regtest -rpcwallet=builderswallet getnewaddress)

bitcoin-cli -regtest generatetoaddress 101 "$ADDR" > /dev/null

bitcoin-cli -regtest -rpcwallet=builderswallet getbalance
