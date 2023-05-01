// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

struct IndexValue {
    uint keyIndex;
    uint value;
}
struct KeyFlag {
    uint key;
    bool deleted;
}

struct itmap {
    mapping(uint => IndexValue) data;
    KeyFlag[] keys;
    uint size;
}

type Iterator is uint;

library IterableMapping {
    function insert(
        itmap storage self,
        uint key,
        uint value
    ) internal returns (bool replaced) {
        uint keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0) return true;
        else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(
        itmap storage self,
        uint key
    ) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0) return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size--;
    }

    function contains(
        itmap storage self,
        uint key
    ) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterateStart(itmap storage self) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, 0);
    }

    function iterateValid(
        itmap storage self,
        Iterator iterator
    ) internal view returns (bool) {
        return Iterator.unwrap(iterator) < self.keys.length;
    }

    function iterateNext(
        itmap storage self,
        Iterator iterator
    ) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, Iterator.unwrap(iterator) + 1);
    }

    function iterateGet(
        itmap storage self,
        Iterator iterator
    ) internal view returns (uint key, uint value) {
        uint keyIndex = Iterator.unwrap(iterator);
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }

    function iteratorSkipDeleted(
        itmap storage self,
        uint keyIndex
    ) private view returns (Iterator) {
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return Iterator.wrap(keyIndex);
    }
}

library circuleBuffer {
    bool private constant PREV = 0;
    bool private constant NEXT = 1;
    int private constant HEAD = 0x0;
    mapping(address => mapping(bool => address)) dllIndex;

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
        dllIndex[dllIndex[_addr][PREV]][NEXT] = dllIndex[_addr][NEXT];
        dllIndex[dllIndex[_addr][NEXT]][PREV] = dllIndex[_addr][PREV];

        // Delete state storage
        delete dllIndex[_addr][PREV];
        delete dllIndex[_addr][NEXT];
    }
}

contract Leaderboard is ERC20 {
    address private owner; // create address for contract owner
    mapping(address => string) public messages; // store stakers messages
    mapping(address => uint) balances;

    struct Entry {
        address addr;
        string message;
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

    function getMessages()
        public
        view
        returns (address[] memory, messages[] memory)
    {
        // address[] memory ret = new address[](100);
        // for (uint i = 0; i < addressRegistryCount; i++) {
        //     ret[i] = addresses[i];
        // }
        // return ();
    }

    /* Implementation using iteratble mappings

    // Just a struct holding our data.
    itmap data;
    // Apply library functions to the data type.
    using IterableMapping for itmap;

    // Insert something
    function insert(uint k, uint v) public returns (uint size) {
        // This calls IterableMapping.insert(data, k, v)
        data.insert(k, v);
        // We can still access members of the struct,
        // but we should take care not to mess with them.
        return data.size;
    }

    // Computes the sum of all stored data.
    function sum() public view returns (uint s) {
        for (
            Iterator i = data.iterateStart();
            data.iterateValid(i);
            i = data.iterateNext(i)
        ) {
            (, uint value) = data.iterateGet(i);
            s += value;
        }
    }

    */
}
