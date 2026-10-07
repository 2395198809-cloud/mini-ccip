// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MiniCCIPReceiver.sol";
import "../src/VulnerableBridge.sol";

contract MiniCCIPTest is Test {
    MiniCCIPReceiver public safeBridge;
    VulnerableBridge public vulnBridge;

    uint256 internal relayerPk = 0xA11CE;
    uint256 internal rmnPk = 0xB0B;
    uint256 internal attackerPk = 0xBAD;

    address internal relayerAddr;
    address internal rmnAddr;

    function setUp() public {
        relayerAddr = vm.addr(relayerPk);
        rmnAddr = vm.addr(rmnPk);

        safeBridge = new MiniCCIPReceiver(relayerAddr, rmnAddr);
        vulnBridge = new VulnerableBridge(relayerAddr);
    }

    function signPayload(uint256 pk, bytes32 merkleRoot, address target) internal view returns (bytes memory) {
        bytes32 payloadHash = keccak256(abi.encodePacked(merkleRoot, block.chainid, target));
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, ethHash);
        return abi.encodePacked(r, s, v);
    }

    function test_DefenseAgainstCompromisedRelayer() public {
        bytes32 msgId = keccak256("msg_malicious");
        uint256 amount = 10 ether;
        address receiver = address(0xCAFE);

        bytes32 leaf = keccak256(abi.encodePacked(msgId, uint256(1), block.chainid, receiver, amount));
        bytes32 root = leaf;
        bytes32[] memory proof = new bytes32[](0);

        bytes memory relayerSig = signPayload(relayerPk, root, address(safeBridge));
        bytes memory forgedRmnSig = signPayload(attackerPk, root, address(safeBridge));

        vm.expectRevert(MiniCCIPReceiver.UnauthorizedSigner.selector);
        safeBridge.executeCrossChainMessage(msgId, 1, receiver, amount, root, proof, relayerSig, forgedRmnSig);
    }

    function test_RateLimitAndCircuitBreakerTrip() public {
        bytes32 msgId = keccak256("msg_whale");
        uint256 drainAmount = 1500 ether;
        address receiver = address(0xCAFE);

        bytes32 leaf = keccak256(abi.encodePacked(msgId, uint256(1), block.chainid, receiver, drainAmount));
        bytes32 root = leaf;
        bytes32[] memory proof = new bytes32[](0);

        bytes memory relayerSig = signPayload(relayerPk, root, address(safeBridge));
        bytes memory rmnSig = signPayload(rmnPk, root, address(safeBridge));

        bool executed = safeBridge.executeCrossChainMessage(msgId, 1, receiver, drainAmount, root, proof, relayerSig, rmnSig);
        assertFalse(executed);
        assertTrue(safeBridge.paused());

        bytes32 msgId2 = keccak256("msg_after_pause");
        bytes32 leaf2 = keccak256(abi.encodePacked(msgId2, uint256(1), block.chainid, receiver, uint256(10 ether)));
        bytes32 root2 = leaf2;
        bytes memory relayerSig2 = signPayload(relayerPk, root2, address(safeBridge));
        bytes memory rmnSig2 = signPayload(rmnPk, root2, address(safeBridge));

        vm.expectRevert(MiniCCIPReceiver.BridgePaused.selector);
        safeBridge.executeCrossChainMessage(msgId2, 1, receiver, 10 ether, root2, proof, relayerSig2, rmnSig2);
    }

    function test_ReplayDefenseOnExecutedMessage() public {
        bytes32 msgId = keccak256("msg_normal");
        uint256 amount = 50 ether;
        address receiver = address(0xCAFE);

        bytes32 leaf = keccak256(abi.encodePacked(msgId, uint256(1), block.chainid, receiver, amount));
        bytes32 root = leaf;
        bytes32[] memory proof = new bytes32[](0);

        bytes memory relayerSig = signPayload(relayerPk, root, address(safeBridge));
        bytes memory rmnSig = signPayload(rmnPk, root, address(safeBridge));

        bool executed = safeBridge.executeCrossChainMessage(msgId, 1, receiver, amount, root, proof, relayerSig, rmnSig);
        assertTrue(executed);

        vm.expectRevert(MiniCCIPReceiver.MessageAlreadyExecuted.selector);
        safeBridge.executeCrossChainMessage(msgId, 1, receiver, amount, root, proof, relayerSig, rmnSig);
    }

    function testFuzz_MerkleInclusionVerification(bytes32 leafA, bytes32 leafB) public view {
        bytes32 root;
        if (leafA <= leafB) {
            root = keccak256(abi.encodePacked(leafA, leafB));
        } else {
            root = keccak256(abi.encodePacked(leafB, leafA));
        }

        bytes32[] memory proofA = new bytes32[](1);
        proofA[0] = leafB;

        assertTrue(safeBridge.verifyMerkleProof(proofA, root, leafA));

        bytes32 forgedLeaf = keccak256(abi.encodePacked(leafA, "tampered"));
        assertFalse(safeBridge.verifyMerkleProof(proofA, root, forgedLeaf));
    }
}
