# Mini-CCIP: Fault-Tolerant Cross-Chain Message Verification & RMN Testbed

[![Foundry](https://img.shields.io/badge/Foundry-Passing-brightgreen)](https://getfoundry.sh/)
[![Go](https://img.shields.io/badge/Go-1.22+blue)](https://go.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A minimal viable production-ready model of a Chainlink CCIP (C-Cross-Chain Interoperability Protocol) node and EVM-native attack testbed. Featuring incremental Merkle Commitments, dual-network authorization (Relayer + RIMN Sentinel), and auto-melting circuit breakers.

---

## System Architecture

```text
[Source Chain Events]
       â”‚
       â•¼ (Goroutines + Concurrent Heuristic Mapping)
[Go CCIP Relayer & RMN Sentinel]
       â”œâ€” Merkle Commitment Engine: Compact Inclusion Proofs
       â”œâ‚T Public Key Cryptography: EIP;EIL-191 Secp256k1 Dual-Signatures
       â”‚
       â•¼ (EVM JSON-RPC)
[MiniCCIPReceiver.sol (Target Chain)]
       â”œâ€” On-Chain Verification: Merkle Inclusion ++ Dual-Signature Recovery
       â”â€” Active Risk Management: Token Bucket Rate Limiting
       â””â€” Compromise Defense: Auto-Pause Circuit Breaker
       â”‚
       â•¼
[Foundry Security Testbed]
       â‘¥8 %ĞÈNˆÛÛ\›ÛZ\ÙY™[^Y\ˆ[\˜Ù\[Ûˆ
ÜXÚX[^™Y“SˆİÛ™Ü˜YJBˆ8¥'8 %ĞÈˆÚ[H[[İ[˜Z[ˆ	ˆÚ\˜İZ]œ™XZÙ\ˆY[ˆ8¥#ø %ĞÈÎˆ^Xİ]YY\ÜØYÙHXİ]™H™\^HY™[˜ÙBˆ8¥#ø %^ˆˆ›Ü\KP˜\ÙYY\šÛH›ÛÙˆ˜[ÙKTÜÚ]]™H[˜\šX[˜‚‹KKB‚ˆÈÈ]ZXÚÈİ\‚‹H›İ[™B‹HÛÈ
HKŒŒJB‚ˆÈÈÈ[ˆ[™]ËQ[™^Xİ][Û‚˜˜\Ú‹‹İ\İÙL™KœÚ˜