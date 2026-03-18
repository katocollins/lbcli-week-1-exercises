#!/bin/bash
bitcoin-cli -regtest validateaddress "bcrt1qckgvfee4qs6y98jrcn8qc0m6ce6sxls0vac3yy" | grep -o '"isvalid":[^,}]*' | cut -d':' -f2 | tr -d ' '

