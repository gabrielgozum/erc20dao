// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

library circuleBuffer {
    bool private constant PREV = 0;
    bool private constant NEXT = 1;
    int256 private constant HEAD = 0x0;
    mapping(address => mapping(bool => address)) dllIndex;

    function add(address _addr) public virtual {
        // Link the new node
        dllIndex[_addr][PREV] = HEAD;
        dllIndex[_addr][NEXT] = dllIndex[HEAD][NEXT];

        // Insert the new node
        dllIndex[dllIndex[HEAD][NEXT]][PREV] = _addr;
        dllIndex[HEAD][NEXT] = _addr;
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

struct IndexValue {
    uint256 keyIndex;
    string value;
}

struct KeyFlag {
    address key;
    bool deleted;
}

struct itmap {
    mapping(address => IndexValue) data;
    KeyFlag[] keys;
    uint256 size;
}

type Iterator is uint256;

library IterableMapping {
    function insert(itmap storage self, address key, string memory value) internal returns (bool replaced) {
        uint256 keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0) {
            return true;
        } else {
            keyIndex = self.keys.length;
            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(itmap storage self, address key) internal returns (bool success) {
        uint256 keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0) return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size--;
    }

    function contains(itmap storage self, address key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }

    function iterateStart(itmap storage self) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, 0);
    }

    function iterateValid(itmap storage self, Iterator iterator) internal view returns (bool) {
        return Iterator.unwrap(iterator) < self.keys.length;
    }

    function iterateNext(itmap storage self, Iterator iterator) internal view returns (Iterator) {
        return iteratorSkipDeleted(self, Iterator.unwrap(iterator) + 1);
    }

    function iterateGet(itmap storage self, Iterator iterator)
        internal
        view
        returns (address key, string memory value)
    {
        uint256 keyIndex = Iterator.unwrap(iterator);
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }

    function iteratorSkipDeleted(itmap storage self, uint256 keyIndex) private view returns (Iterator) {
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted) {
            keyIndex++;
        }
        return Iterator.wrap(keyIndex);
    }
}

contract Leaderboard is ERC20 {
    address private owner; // create address for contract owner

    mapping(address => uint256) balances;

    // Just a struct holding our data.
    itmap data;

    // Apply library functions to the data type.
    using IterableMapping for itmap;

    // mapping(address => string) public messages; // store stakers messages
    // struct Entry {
    //     address addr;
    //     string message;
    // }

    constructor() ERC20("Leaderboard", "LDB") {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount, string memory message) public virtual {
        // assert sender address is the contract owner
        assert(msg.sender == owner);
        _mint(to, amount);
        insert(to, message); // map address to message
        // messages[to] = message;
    }

    function burn(address form, uint256 amount) public virtual {
        _burn(form, amount);
    }

    // Insert something
    function insert(address k, string memory v) public returns (uint256 size) {
        // This calls IterableMapping.insert(data, k, v)
        data.insert(k, v);
        // We can still access members of the struct, but we should take care not to mess with them.
        return data.size;
    }

    function getMessage(address addr) public view returns (string memory) {
        // return messages[user];
        return data[addr].value;
    }

    function getMessages() public view returns (address[] memory, messages[] memory) {
        // for (Iterator i = data.iterateStart(); data.iterateValid(i); i = data.iterateNext(i)) {
        //     (, string memory value) = data.iterateGet(i);
        //     // do something
        // }

        // // ---------

        // uint256 len = 50;
        // // address[] memory addressList = new address[](len);
        // address[] memory addressList;
        // string[] memory messageList;

        // addressList.push(0x0);

        // return (addressList, messageList);
    }
}
