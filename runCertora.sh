#!/bin/bash

# Load Certora settings
source certora_settings.env

# Load CERTORAKEY
export CERTORAKEY=$(node load-env.js)

echo "CERTORAKEY is set to: $CERTORAKEY"

# certoraRun contracts/piNFT.sol \
#     --verify piNFT:certora/piNFT.spec \
#     --optimistic_loop \
#     --loop_iter 3 \
#     --solc_via_ir \
#     --solc_optimize 1000000 \
#     --msg "Verification of piNFT"

# certoraRun contracts/piNFTMethods.sol \
#     --verify piNFTMethods:certora/piNFTMethods.spec \
#     --optimistic_loop \
#     --loop_iter 3 \
#     --solc_via_ir \
#     --solc_optimize 1000000 \
#     --msg "Verification of piNFTMethods"

# certoraRun contracts/NFTlendingBorrowing.sol    \
#  --verify NFTlendingBorrowing:certora/NFTlendingBorrowing.spec  \
#     --optimistic_loop \
#     --loop_iter 3 \
#     --solc_via_ir \
#     --solc_optimize 1000000 \
#     --msg "Verification of NFTlendingBorrowing"

# certoraRun contracts/NFTlendingBorrowing.sol    \
#  --verify NFTlendingBorrowing:certora/NFTlendingBorrowing.spec  \
#  --optimistic_loop \
#  --optimistic_summary_recursion \
#  --optimistic_fallback \
#  --summary_recursion_limit 300 \
#  --nondet_difficult_funcs \
#  --optimistic_hashing \
#  --hashing_length_bound 128 \
#     --loop_iter 3 \
#     --solc_via_ir \
#     --solc_optimize 1000000 \
#     --msg "Verification of NFTLendingBorrowing" \
#     --packages @openzeppelin=node_modules/@openzeppelin \
#     --multi_assert_check \
#     --rule_sanity \
#     --send_only

certoraRun contracts/CollectionFactory.sol    \
 --verify CollectionFactory:certora/CollectionFactory.spec  \
    --optimistic_loop \
    --loop_iter 3 \
    --solc_via_ir \
    --solc_optimize 1000000 \
    --msg "Verification of NFTlendingBorrowing"