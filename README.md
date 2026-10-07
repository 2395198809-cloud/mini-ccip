# Mini-CCIP: Fault-Tolerant Cross-Chain Message Verification & RMN Testbed

[![Foundry](https://img.shields.io/badge/Foundry-Passing-brightgreen)](https://getfoundry.sh/)
[![Go](https://img.shields.io/badge/Go-1.22-blue)](https://go.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A minimal viable production-ready model of a Chainlink CCIP (C-Cross-Chain Interoperability Protocol) node and EVM-native attack testbed. Featuring incremental Merkle Commitments, dual-network authorization (Relayer + RIMN Sentinel), and auto-melting circuit breakers.

---

## System Architecture

```text
[Source Chain Events]
         |
         v (Goroutines + Concurrent Heuristic Mapping)
[Go CCIP Relayer & RMN Sentinel]
         |-- Merkle Commitment Engine: Compact Inclusion Proofs
         |-- Public Key Cryptography: EIP-191 Secp256k1 Dual-Signatures
         |
         v (EVM JSON-RPC)
[MiniCCIPReceiver.sol (Target Chain)]
         |-- On-Chain Verification: Merkle Inclusion + Dual-Signature Recovery
         |-- Active Risk Management: Token Bucket Rate Limiting
         |-- Compromise Defense: Auto-Pause Circuit Breaker
         |
         v
[Foundry Security Testbed]
         |-- PoC 1: Compromised Relayer Interception (RMN Sentinel Rejection)
         |-- PoC 2: Whale Drain & Circuit Breaker Melt (Auto-Pause)
         |-- PoC 3: Executed Message Active Replay Defense
         \-- Fuzz 4: Property-Based Merkle Proof False-Positive Invariant (256 runs)
```

---

## Technical Highlights

- Dual-Network Defense (Relayer + RIN): Two isolated signing layers. Malicious feeds rejected without RMN approval.
- Compact Merkle Commitments: Compresses messages into a Merkle Root, verified via minimal O(log N) proofs.
- Dynamic Rate Limiting: Token-bucket capacity auto-trips circuit breaker upon high-velocity drain.

---

## Quick Start

- Foundry
- Go (>= 1.21)

### Run End-to-End Execution
```bash
./test_e2e.sh
```
