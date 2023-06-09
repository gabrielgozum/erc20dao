// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/ERC20.sol";

struct Circular {
    mapping(address => mapping(bool => address)) dllIndex;
}

library circuleBuffer {
    bool private constant PREV = false;
    bool private constant NEXT = true;
    address private constant HEAD = address(0); // 0x0

    function add(Circular storage self, address _addr) internal {
        // Link the new node
        self.dllIndex[_addr][PREV] = HEAD;
        self.dllIndex[_addr][NEXT] = self.dllIndex[HEAD][NEXT];

        // Insert the new node
        self.dllIndex[self.dllIndex[HEAD][NEXT]][PREV] = _addr;
        self.dllIndex[HEAD][NEXT] = _addr;
    }

    function remove(Circular storage self, address _addr) internal {
        // Stitch the neighbours together
        self.dllIndex[self.dllIndex[_addr][PREV]][NEXT] = self.dllIndex[_addr][NEXT];
        self.dllIndex[self.dllIndex[_addr][NEXT]][PREV] = self.dllIndex[_addr][PREV];

        // Delete state storage
        delete self.dllIndex[_addr][PREV];
        delete self.dllIndex[_addr][NEXT];
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

library iterableMapping {
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
    itmap dataIterable;

    using iterableMapping for itmap; // Apply library functions to the data type.

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
        // assert(msg.sender == owner);
        _mint(to, amount);
        insert(to, message); // map address to message
            // messages[to] = message;
    }

    function burn(address form, uint256 amount) public virtual {
        _burn(form, amount);
    }

    // Insert something
    function insert(address k, string memory v) internal returns (uint256 size) {
        // This calls IterableMapping.insert(data, k, v)
        dataIterable.insert(k, v);
        // We can still access members of the struct, but we should take care not to mess with them.
        return dataIterable.size;
    }

    function getMessage(address addr) public view returns (string memory) {
        require(dataIterable.contains(addr)); 

        // return messages[user];
        return dataIterable.data[addr].value;
    }

    function getMessages(uint256 len) public view returns (address[] memory, string[] memory, uint256[] memory) {
        require(len < 1000); // support maximum of thousand shareholders

        // NOTE: storing the entire address in contract's storage is very expensive, but it is used for demostration only.
        address[] memory addressList = new address[](len);
        string[] memory messageList = new string[](len);
        uint256[] memory balanceList = new uint256[](len);

        uint c = 0; 
        for (Iterator i = dataIterable.iterateStart(); dataIterable.iterateValid(i); i = dataIterable.iterateNext(i)) {
            (address key, string memory value) = dataIterable.iterateGet(i);
            addressList[c] = key;
            messageList[c] = value;
            balanceList[c] = balanceOf(key); 
            c++;
        }

        return (addressList, messageList, balanceList);
    }
}
