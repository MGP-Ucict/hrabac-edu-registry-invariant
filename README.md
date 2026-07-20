# HRABAC Blockchain-Anchored Recovery Protocol

This repository contains the formal verification source code for the off-chain database snapshot recovery subsystem of the **HRABAC** (Deterministic Hybrid Role-Attribute Based Access Control) framework. 

The system utilizes an immutable blockchain ledger to anchor cryptographic hashes (Merkle Roots) of historical database states, enabling decentralized, automated verification and **Point-in-Time Recovery (PITR)** in the event of localized data corruption, ransomware deployment, or unauthorized data tampering.

This repository contains the formal specification of the HRABAC Recovery mechanism—a security and Point-in-Time Recovery (PITR) framework that utilizes an immutable on-chain distributed ledger as a root of trust (Anchor) to secure and restore off-chain state histories.The model is written in TLA+ and verified using the TLC Model Checker.


## 📌 Model Architecture

The specification models a system composed of three core state variables:offchainDB: The active, live state of the off-chain database. It can reside either in a trusted state (ValidStates) or be compromised by an attacker (CorruptedStates).snapshots: A sequence representing historical point-in-time backups of the database stored off-chain.onchainLedger: An append-only, immutable sequence of Merkle roots (hashes) anchored to the blockchain, serving as cryptographic proof of historical truth.

## ⚙️ System Actions (Transitions)

The state space transitions through the following legal operations:AnchorAndSnapshot: The Inspector backs up the current valid database state and anchors its corresponding Merkle root to the immutable on-chain ledger.AdversarialMutation: An adversary executes an unauthorized write operation, forcing the live database into a compromised state.RecoverySuccess: If a cryptographic match is found between an off-chain snapshot and an on-chain root, the system automatically rolls back the active database to the latest verified valid state. RecoveryFailed: If an attack occurs before any valid snapshot is anchored on-chain, the system safely falls back into a permanent failure state ("Permanent_Failure"). SystemTerminated: A safe stuttering loop that prevents false deadlocks after a terminal failure state is reached.

## Formal Verification Architecture

The synchronization layer is formally modeled and verified using **TLA+ (Temporal Logic of Actions)** and verified via the **TLC Model Checker** to evaluate safety properties across 100% of the reachable state space exploration graph.

### Protocol Mechanics:
1. **Dynamic Generation:** When data verification is initialized, the system reconstructs the off-chain data array, hashing the target snapshot state into a Merkle Root (`MR(S_i)`).
2. **On-Chain Matching:** The recovery engine processes the chronological history in reverse order. It compares the root against the array of state anchors statefully registered on-chain (`B_i`) by the authorized inspector role.
3. **Safety Invariant Protection:** If an adversary introduces an unauthorized mutation (such as `Snapshot_April_Adversarial`), the avalanche effect forces a hash discrepancy (`MR(S_j) != B_j`). The corrupted state is instantly discarded, and the system rolls back the database strictly to the newest verified checkpoint matching the consensus anchor.

## Verification Execution Output

When processed through the TLC Model Checker engine, the configuration generates the following structural evaluation profile:

* **States Generated:** 39 states
* **Distinct States Discovered:** 23 unique configurations
* **Max Graph Execution Depth:** 5 levels 
 **Verification Status:** `Success: No error has been found.`

This verification profile demonstrates that the HRABAC recovery topology achieves absolute structural safety, eliminating manual administrative evaluation pitfalls and making the model resilient against state corruption under all valid transaction routing behaviors.
