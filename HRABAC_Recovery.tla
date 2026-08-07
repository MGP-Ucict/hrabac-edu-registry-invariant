--------------------------- MODULE HRABAC_Recovery ---------------------------
EXTENDS Naturals, Sequences

CONSTANTS ValidStates,      \* The set of uncorrupted database states
          CorruptedStates   \* The set of states manipulated by an adversary

VARIABLES offchainDB,       \* The active state of the off-chain database
          snapshots,        \* Sequence of generated historical snapshots (off-chain)
          onchainLedger     \* Sequence of immutable Merkle roots anchored on-chain

vars == <<offchainDB, snapshots, onchainLedger>>

\* Abstract representation of the Merkle Root function
MerkleRoot(state) == state

\* System initialization state
Init == 
    /\ offchainDB \in ValidStates
    /\ snapshots = << >>
    /\ onchainLedger = << >>

\* Action 1: The Inspector creates a snapshot and anchors its Merkle root on-chain
AnchorAndSnapshot ==
    /\ Len(snapshots) < 3
    /\ offchainDB \in ValidStates 
    /\ snapshots' = Append(snapshots, offchainDB)
    /\ onchainLedger' = Append(onchainLedger, MerkleRoot(offchainDB))
    /\ UNCHANGED <<offchainDB>>

\* Action 2: The Adversary executes an unauthorized mutation on the live active database
AdversarialMutation ==
    /\ offchainDB \in ValidStates   
    /\ offchainDB' \in CorruptedStates
    /\ UNCHANGED <<snapshots, onchainLedger>>

\* Action 3: Successful Point-in-Time Recovery triggered by existing valid anchored snapshots
RecoverySuccess ==
    LET Matches == {k \in 1..Len(snapshots) : MerkleRoot(snapshots[k]) = onchainLedger[k]}
    IN /\ offchainDB \in CorruptedStates
       /\ Matches /= {}
       /\ LET k == CHOOSE x \in Matches : \A y \in Matches : x >= y
          IN offchainDB' = snapshots[k]
       /\ UNCHANGED <<snapshots, onchainLedger>>

\* Action 4: Fallback execution path when an attack occurs before any snapshot is anchored
RecoveryFailed ==
    LET Matches == {k \in 1..Len(snapshots) : MerkleRoot(snapshots[k]) = onchainLedger[k]}
    IN /\ offchainDB \in CorruptedStates
       /\ Matches = {}
       /\ offchainDB' = "Permanent_Failure"
       /\ UNCHANGED <<snapshots, onchainLedger>>

\* Action 5: Safe stuttering step to prevent deadlocks after terminal failure state is reached
SystemTerminated ==
    /\ offchainDB = "Permanent_Failure"
    /\ UNCHANGED vars

\* Next state relation governing legal transitions
Next == 
    \/ AnchorAndSnapshot
    \/ AdversarialMutation
    \/ RecoverySuccess
    \/ RecoveryFailed
    \/ SystemTerminated

\* System specification with Stronger Fairness constraints to force execution of recovery actions
Spec == Init /\ [][Next]_vars /\ WF_vars(RecoverySuccess) /\ WF_vars(RecoveryFailed)

\* SAFETY INVARIANT: Validates that on-chain roots never match corrupted historical snapshots
SafetyInvariant == 
    \A k \in 1..Len(snapshots) : (MerkleRoot(snapshots[k]) = onchainLedger[k]) => (snapshots[k] \in ValidStates)

\* CORRECTED LIVENESS PROPERTY: Guarantees that if an attack occurs, the system will either 
\* successfully recover to a valid state, OR gracefully transit to a designated Permanent_Failure state.
LivenessProperty == 
    (offchainDB \in CorruptedStates) ~> (offchainDB \in ValidStates \/ offchainDB = "Permanent_Failure")

============================================================================
