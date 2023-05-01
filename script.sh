#!/bin/bash

# "forged" tools

deploy() {
  forge create Leaderboard --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --verify --constructor-args Leaderboard LDB
  cast send --rpc-url=$RPC_URL 0xEf84bE8dFc4B529F5e544d8B8D678f1b223F2B51 "mint(address, uint256)" 0x89BF19105d76033F328C54B8DDeA404A4b282Ef8 100000 --private-key=$PRIVATE_KEY
}
