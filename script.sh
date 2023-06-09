#!/bin/bash

# "forged" tools

deploy() {
  forge create Leaderboard --rpc-url=$RPC_URL --private-key=$PRIVATE_KEY --verify --constructor-args Leaderboard LDB
  cast send --rpc-url=$RPC_URL 0xEf84bE8dFc4B529F5e544d8B8D678f1b223F2B51 "mint(address, uint256)" 0x89BF19105d76033F328C54B8DDeA404A4b282Ef8 100000 --private-key=$PRIVATE_KEY
}

install() {
  npm install -g solc
  curl -L https://foundry.paradigm.xyz | bash
  npm install -g @remix-project/remixd
}

initialize_repo() {
  git submodule update --init --remote
  git submodule update --init --recursive
}

development_remix() {
  remixd # run local server

  # open and integrate: remix.ethereum.org
}

dev_forge() {
  forge build
  forge test -vv
  forge test --gas-report
}
