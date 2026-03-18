#!/bin/bash
bitcoin-cli -regtest getblockchaininfo | grep -o '"chain":"[^"]*"' | cut -d'"' -f4
