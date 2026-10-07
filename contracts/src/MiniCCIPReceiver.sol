// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MiniCCIPReceiver {
    address public immutable primaryRelayer;
    address public immutable riskManager;
    uint256 public immutable chainId;

    uint256 public constant RATE_LIMIT_CAPACITY = 1000 ether;
    uint256 public constant RATE_LIMIT_REFILL_RATE = 1 ether;

    uint256 public currentBucketTokens;
    uint256 public lastBucketRefillTimestamp;
    bool public paused;

    mapping(bytes32 => bool) public executedMessages;

    event MessageExecuted(bytes32 indexed messageId, address indexed receiver, uint256 amount);
    event CircuitBreakerTripped(bytes32 indexed reason);

    error UnauthorizedSigner();
    error MessageAlreadyExecuted();
    error InvalidMerkleProof();
    error BridgePaused();

    constructor(address _primaryRelayer, address _riskManager) {
        primaryRelayer = _primaryRelayer;
        riskManager = _riskManager;
        chainId = block.chainid;
        currentBucketTokens = RATE_LIMIT_CAPACITY;
        lastBucketRefillTimestamp = block.timestamp;
    }

    function refillRateLimitBucket() internal {
        uint256 elapsed = block.timestamp - lastBucketRefillTimestamp;
        if (elapsed > 0) {
            uint256 refill = elapsed * RATE_LIMIT_REFILL_RATE;
            if (currentBucketTokens + refill > RATE_LIMIT_CAPACITY) {
                currentBucketTokens = RATE_LIMIT_CAPACITY;
            } else {
                currentBucketTokens += refill;
            }
            lastBucketRefillTimestamp = block.timestamp;
        }
    }

    function verifyMerkleProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) public pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash == root;
    }

    function executeCrossChainMessage(
        bytes32 messageId,
        uint256 sourceChainId,
        address receiver,
        uint256 amount,
        bytes32 merkleRoot,
        bytes32[] memory proof,
        bytes memory relayerSig,
        bytes memory rmnSig
    ) external returns (bool success) {
        if (paused) revert BridgePaused();
        if (executedMessages[messageId]) revert MessageAlreadyExecuted();

        bytes32 leaf = keccak256(abi.encodePacked(messageId, sourceChainId, chainId, receiver, amount));
        if (!verifyMerkleProof(proof, merkleRoot, leaf)) revert InvalidMerkleProof();

        bytes32 payloadHash = keccak256(abi.encodePacked(merkleRoot, chainId, address(this)));
        bytes32 ethSignedPayloadHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", payloadHash));

        if (recoverSigner(ethSignedPayloadHash, relayerSig) != primaryRelayer) revert UnauthorizedSigner();
        if (recoverSigner(ethSignedPayloadHash, rmnSig) != riskManager) revert UnauthorizedSigner();

        refillRateLimitBucket();
        if (amount > currentBucketTokens) {
            paused = true;
            emit CircuitBreakerTripped(keccak256("RATE_LIMIT_EXCEEDED"));
            return false;
        }

        currentBucketTokens -= amount;
        executedMessages[messageId] = true;

        emit MessageExecuted(messageId, receiver, amount);
        return true;
    }

    function recoverSigner(bytes32 digest, bytes memory sig) internal pure returns (address) {
        if (sig.length != 65) revert UnauthorizedSigner();
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(digest, v, r, s);
    }
}
