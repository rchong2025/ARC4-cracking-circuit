# Hardware ARC4 Key Cracking Accelerator (SystemVerilog)

A hardware-based brute-force key cracking system for the ARC4 stream cipher, designed in SystemVerilog and targeted for Intel FPGAs. The design progresses from low-level cipher state initialization to a multi-core parallel key search architecture.

## Overview

ARC4 encryption relies on a permutation vector $S$ initialized via a Key Scheduling Algorithm (KSA) and mutated via a Pseudo-Random Generation Algorithm (PRGA). This project implements:
1. **KSA State Machine:** Initializes and secret-key-scrambles the 256-byte S-memory array.
2. **PRGA Engine:** Generates keystream bytes and computes XOR decryption with input ciphertext.
3. **Single-Core Cracker:** Iterates through candidate 24-bit key spaces, checking decrypted output bytes against valid ASCII ranges.
4. **Multi-Core Parallel Cracker (`doublecrack`):** Distributes key-space evaluation across parallel cracking engines to halve total decryption latency.

## Hardware Architecture & Modules

- **`init.sv`**: Resets and linearly populates the 256-byte S-array (`0` to `255`).
- **`ksa.sv`**: Swaps array elements based on key bytes to produce the initial permutation.
- **`prga.sv`**: Generates keystream bytes and decrypts ciphertext into target plaintext RAM.
- **`crack.sv`**: Orchestrates state machines for brute-force key space evaluation.
- **`doublecrack.sv`**: Parallelized top-level cracker splitting key space across dual crack engines.
- **`seg7.sv`**: Seven-segment LED display decoder for displaying found secret keys on-board.

## Repository Structure

```text
├── rtl/           # Core SystemVerilog RTL design modules
├── tb/            # RTL and Gate-Level post-synthesis testbenches
├── mem/           # On-chip RAM IP blocks (Ciphertext, Plaintext, S-Memory)
├── task5.qpf      # Quartus Prime project file
└── task5.qsf      # Quartus Prime settings & pin assignments
