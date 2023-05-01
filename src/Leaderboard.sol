// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Leaderboard is ERC20 {
    // create address for contract owner
    address private owner;
    string public message = "This is a message";

    constructor() ERC20("Leaderboard", "LDB") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) public virtual {
        // assert sender address is the contract owner
        assert(msg.sender == owner);
        _mint(to, amount);
    }

    function burn(address form, uint amount) public virtual {
        _burn(form, amount);
    }

    function getMessage() public virtual returns(string memory) {
        return (message); 
    }
}
