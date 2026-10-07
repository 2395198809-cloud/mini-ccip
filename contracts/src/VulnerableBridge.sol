// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract VulnerableBridge {
    address public relayer;
    mapping(bytes32 => bool) public executed;

    constructor(address _relayer) {
        relayer = _relayer;
    }

    function execute(bytes32 messageId, address receiver, uint256 amount, bytes memory sig) external {
        if (executed[messageId]) revert("Executed");

        bytes32 hash = keccak256(abi.encodePacked(messageId, receiver, amount));
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        if (ecrecover(ethHash, v, r, s) != relayer) revert("Unauthorized");

        executed[messageId] = true;
    }
}
