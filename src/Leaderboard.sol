// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract Leaderboard is ERC20 {
    bool private constant PREV = 0;
    bool private constant NEXT = 1;
    int private constant HEAD = 0x0; 

    address private owner; // create address for contract owner
    // garabage collection: https://ethereum.stackexchange.com/questions/15337/can-we-get-all-elements-stored-in-a-mapping-in-the-contract
    mapping(address => string) public messages; // store stakers messages
    mapping(address => mapping(bool => address)) dllIndex;
    mapping(address => uint) balances;

    function add(address _addr) public virtual {
        // Link the new node 
        dllIndex[_addr][PREV] = 0x0;
        dllIndex[_addr][NEXT] = dllIndex[0x0][NEXT];

        // Insert the new node
        dllIndex[dllIndex[0x0][NEXT]][PREV] = _addr;
        dllIndex[0x0][NEXT] = _addr;
    }

    function remove(address _addr) public virtual {
        // Stitch the neighbours together
        dllIndex[ dllIndex[_addr][PREV] ][NEXT] = dllIndex[_addr][NEXT];
        dllIndex[ dllIndex[_addr][NEXT] ][PREV] = dllIndex[_addr][PREV];

        // Delete state storage
        delete dllIndex[_addr][PREV];
        delete dllIndex[_addr][NEXT];
        delete balances[_addr];
    }

    constructor() ERC20("Leaderboard", "LDB") {
        owner = msg.sender;
    }

    function mint(
        address to,
        uint256 amount,
        string memory message
    ) public virtual {
        // assert sender address is the contract owner
        assert(msg.sender == owner);
        _mint(to, amount);
        messages[to] = message;
    }

    function burn(address form, uint amount) public virtual {
        _burn(form, amount);
    }

    function getMessage(address user) public view returns (string memory) {
        return messages[user];
    }
     
    function getAllMessage() public view returns (address[] memory, messages[] memory) {

        address[] memory ret = new address[](addressRegistryCount);
        for (uint i = 0; i < addressRegistryCount; i++) {
            ret[i] = addresses[i];
        }
        return messages;
    }
}
