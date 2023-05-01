// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Leaderboard is ERC20 {
    // create address for contract owner
    address private owner;
    mapping(address => string) private messages;

    constructor() ERC20("Leaderboard", "LDB") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount, string memory message) public virtual {
        // assert sender address is the contract owner
        assert(msg.sender == owner);
        _mint(to, amount);
        messages[to] = message;
    }


    function burn(address form, uint amount) public virtual {
        _burn(form, amount);
    }

    function getMessage(address user) public virtual returns(string memory) {
        return messages[user]; 
    }
}
