pragma solidity ^0.5.16;

import "./Owned.sol";


contract AddressResolver is Owned {
    mapping(bytes32 => address) public repository;

    constructor(address _owner) public Owned() {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function importAddresses(bytes32[] memory names, address[] memory destinations) public onlyOwner {
        require(names.length == destinations.length, "Input lengths must match");

        for (uint i = 0; i < names.length; i++) {
            repository[names[i]] = destinations[i];
        }
    }

    /* ========== VIEWS ========== */

    function getAddress(bytes32 name) public view returns (address) {
        return repository[name];
    }

    function requireAndGetAddress(bytes32 name, string memory reason) public view returns (address) {
        address _foundAddress = repository[name];
        require(_foundAddress != address(0), reason);
        return _foundAddress;
    }
}
