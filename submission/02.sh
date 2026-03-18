#!/bin/bash
bitcoin-cli -regtest getblockchaininfo | jq -r '.chain'