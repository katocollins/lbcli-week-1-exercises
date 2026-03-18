#!/bin/bash

source .github/functions.sh

set -e

setup_challenge

echo "CHALLENGE 1: Create your explorer wallet"
echo "----------------------------------------"
bitcoin-cli -regtest createwallet "btrustwallet"
bitcoin-cli -regtest createwallet "treasurewallet"

TREASURE_ADDR=$(bitcoin-cli -regtest -rpcwallet=treasurewallet getnewaddress "" "bech32")
check_cmd "Address generation"
echo "Mining to address: $TREASURE_ADDR"

mine_blocks 101 $TREASURE_ADDR

echo ""
echo "CHALLENGE 2: Check your starting resources"
echo "-----------------------------------------"
BALANCE=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getbalance)
check_cmd "Balance check"
echo "Your starting balance: $BALANCE BTC"

echo ""
echo "CHALLENGE 3: Create a set of addresses for your exploration"
echo "---------------------------------------------------------"
LEGACY_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" "legacy")
check_cmd "Legacy address generation"

P2SH_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" "p2sh-segwit")
check_cmd "P2SH address generation"

SEGWIT_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" "bech32")
check_cmd "SegWit address generation"

TAPROOT_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" "bech32m")
check_cmd "Taproot address generation"

echo "Your exploration addresses:"
echo "- Legacy treasure map: $LEGACY_ADDR"
echo "- P2SH ancient vault: $P2SH_ADDR"
echo "- SegWit digital safe: $SEGWIT_ADDR"
echo "- Taproot quantum vault: $TAPROOT_ADDR"

echo ""
echo "The treasure hunt begins! Coins are being sent to your addresses..."

send_with_fee "treasurewallet" "$LEGACY_ADDR" 1.0 "First clue: Verify this transaction"
send_with_fee "treasurewallet" "$P2SH_ADDR" 2.0 "Second clue: Needs validation"
send_with_fee "treasurewallet" "$SEGWIT_ADDR" 3.0 "Third clue: Check descriptor"
send_with_fee "treasurewallet" "$TAPROOT_ADDR" 4.0 "Final clue: Message verification"

mine_blocks 6 $TREASURE_ADDR

echo ""
echo "CHALLENGE 4: Count your treasures"
echo "-------------------------------"
NEW_BALANCE=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getbalance)
check_cmd "New balance check"
echo "Your treasure balance: $NEW_BALANCE BTC"

COLLECTED=$(echo "$NEW_BALANCE - $BALANCE" | bc)
check_cmd "Balance calculation"
echo "You've collected $COLLECTED BTC in treasures!"

echo ""
echo "CHALLENGE 5: Validate the ancient vault address"
echo "--------------------------------------------"
P2SH_VALID=$(bitcoin-cli -regtest validateaddress "$P2SH_ADDR" | jq -r '.isvalid')
check_cmd "Address validation"
echo "P2SH vault validation: $P2SH_VALID"

if [[ "$P2SH_VALID" == "true" ]]; then
  echo "Vault is secure! You may proceed to the next challenge."
else
  echo "WARNING: Vault security compromised!"
  exit 1
fi

echo ""
echo "CHALLENGE 6: Decode the hidden message"
echo "------------------------------------"
SECRET_MESSAGE="You've successfully completed the Bitcoin treasure hunt!"
SIGNATURE=$(bitcoin-cli -regtest -rpcwallet=btrustwallet signmessage $LEGACY_ADDR "$SECRET_MESSAGE")
check_cmd "Message signing"
echo "Address: $LEGACY_ADDR"
echo "Signature: $SIGNATURE"

echo "In an interactive environment, you would guess the message content."
echo "For CI testing, we'll verify the correct message directly:"

VERIFY_RESULT=$(bitcoin-cli -regtest verifymessage "$LEGACY_ADDR" "$SIGNATURE" "$SECRET_MESSAGE")
check_cmd "Message verification"
echo "Message verification result: $VERIFY_RESULT"

if [[ "$VERIFY_RESULT" == "true" ]]; then
  echo "Message verified successfully! The secret message is:"
  echo "\"$SECRET_MESSAGE\""
else
  echo "ERROR: Message verification failed!"
  exit 1
fi

echo ""
echo "CHALLENGE 7: The descriptor treasure map"
echo "-------------------------------------"
NEW_TAPROOT_ADDR=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getnewaddress "" "bech32m")
check_cmd "New taproot address generation"
NEW_TAPROOT_ADDR=$(trim "$NEW_TAPROOT_ADDR")

ADDR_INFO=$(bitcoin-cli -regtest -rpcwallet=btrustwallet getaddressinfo "$NEW_TAPROOT_ADDR")
check_cmd "Getting address info"

# Extract the descriptor from address info, then pull the key out of it
# In v28, the desc field looks like: tr([fingerprint/path]xpub...)#checksum
# We need the raw pubkey - get it from the pubkey field or parse the descriptor
INTERNAL_KEY=$(echo "$ADDR_INFO" | jq -r '.pubkey // empty')

# If pubkey not available, extract from the descriptor
if [[ -z "$INTERNAL_KEY" ]]; then
  RAW_DESC=$(echo "$ADDR_INFO" | jq -r '.desc // empty')
  # descriptor looks like tr([d6043800/86h/1h/0h/0/0]xpubKEY)#checksum
  # extract just the key inside tr()
  INTERNAL_KEY=$(echo "$RAW_DESC" | grep -oP 'tr\(\K[^)#]+' | sed "s/\[.*\]//")
fi

check_cmd "Extracting key from descriptor"
INTERNAL_KEY=$(trim "$INTERNAL_KEY")

echo "Using internal key: $INTERNAL_KEY"
SIMPLE_DESCRIPTOR="tr($INTERNAL_KEY)"
echo "Simple descriptor: $SIMPLE_DESCRIPTOR"

TAPROOT_DESCRIPTOR=$(bitcoin-cli -regtest getdescriptorinfo "$SIMPLE_DESCRIPTOR" | jq -r '.descriptor')
check_cmd "Descriptor generation"
TAPROOT_DESCRIPTOR=$(trim "$TAPROOT_DESCRIPTOR")
echo "Taproot treasure map: $TAPROOT_DESCRIPTOR"

DERIVED_ADDR_RAW=$(bitcoin-cli -regtest deriveaddresses "$TAPROOT_DESCRIPTOR")
check_cmd "Address derivation"
DERIVED_ADDR=$(echo "$DERIVED_ADDR_RAW" | jq -r '.[0]')
echo "Derived quantum vault address: $DERIVED_ADDR"

echo "New taproot address: $NEW_TAPROOT_ADDR"
echo "Derived address:     $DERIVED_ADDR"

echo "Address lengths: ${#NEW_TAPROOT_ADDR} vs ${#DERIVED_ADDR}"
echo "Address comparison (base64 encoded to see any hidden characters):"
echo "New:     $(echo -n "$NEW_TAPROOT_ADDR" | base64)"
echo "Derived: $(echo -n "$DERIVED_ADDR" | base64)"

if [[ "$NEW_TAPROOT_ADDR" == "$DERIVED_ADDR" ]]; then
  echo "Addresses match! The final treasure is yours!"
  echo ""
  echo "Note: In Bitcoin Core v28, the original taproot address used in the challenge was:"
  echo "Original address: $TAPROOT_ADDR"
else
  echo "ERROR: Address mismatch detected!"
  echo "New taproot address: $NEW_TAPROOT_ADDR"
  echo "Derived address:     $DERIVED_ADDR"
  exit 1
fi

echo ""
echo "TREASURE HUNT COMPLETE!"
echo "======================="
show_wallet_info "btrustwallet"
echo ""
echo "Congratulations on completing the Bitcoin treasure hunt!"