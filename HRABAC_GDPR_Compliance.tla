------------------- MODULE GDPRCompliance -------------------
EXTENDS Sequences, Integers

(*---------------------------------------------------------------------------
  CONSTANTS DEFINITIONS
  Students: The set of unique student identities (e.g., {Stu1, Stu2}).
  PlaintextPII: Map or set containing sensitive data.
 ---------------------------------------------------------------------------*)
CONSTANTS Students, PlaintextPII

VARIABLES
    offChainPII,       (* The state of the localized off-chain database tier *)
    ephemeralKey,      (* The state of the Ephemeral Key Registry (Symmetric keys) *)
    onChainHash,       (* The immutable public blockchain data slot ledger *)
    isLinked           (* Dynamic safety tracking mapping to monitor data linkability *)

vars == <<offChainPII, ephemeralKey, onChainHash, isLinked>>

(*---------------------------------------------------------------------------
  INITIAL SYSTEM STATE
  To avoid the deterministic CHOOSE bottleneck, we map each student directly 
  to a distinct PII record (assuming a one-to-one relation for model checking).
 ---------------------------------------------------------------------------*)
Init ==
    /\ offChainPII = [s \in Students |-> [pii |-> s, status |-> "ACTIVE"]]
    /\ ephemeralKey = [s \in Students |-> [key |-> "ValidKey32Bytes", isActive |-> TRUE]]
    /\ onChainHash = [s \in Students |-> "ImmutableKeccak256Hash"]
    /\ isLinked = [s \in Students |-> TRUE]

(*---------------------------------------------------------------------------
  ACTION: ExecuteGDPRRightToForget
  Models the infrastructure-enforced cryptographic shredding routine.
  The institutional database overwrites PII and purges the decryption key,
  breaking the linkability vector irrevocably.
 ---------------------------------------------------------------------------*)
ExecuteGDPRRightToForget(student) ==
    /\ student \in Students
    /\ offChainPII[student].status = "ACTIVE"
    /\ ephemeralKey' = [ephemeralKey EXCEPT ![student] = [key |-> "0x0000", isActive |-> FALSE]]
    /\ offChainPII' = [offChainPII EXCEPT ![student] = [pii |-> "ErasedPII", status |-> "SHREDDED"]]
    /\ isLinked' = [isLinked EXCEPT ![student] = FALSE]
    /\ UNCHANGED <<onChainHash>>

(*---------------------------------------------------------------------------
  ACTION: Idle
  Prevents TLC model checker from throwing a false-positive deadlock exception
  once all data instances have reached their terminal shredded state topology.
 ---------------------------------------------------------------------------*)
Idle ==
    /\ \forall s \in Students : offChainPII[s].status = "SHREDDED"
    /\ UNCHANGED vars

(*---------------------------------------------------------------------------
  NEXT-STATE RELATION
 ---------------------------------------------------------------------------*)
Next ==
    \/ \E s \in Students : ExecuteGDPRRightToForget(s)
    \/ Idle

(*---------------------------------------------------------------------------
  FORMAL MATHEMATICAL SYSTEM INVARIANT (INVARIANT 4)
  Proof Verification Goal: If a student's data is shredded and their key is 
  deactivated, it is mathematically guaranteed that the linkability is destroyed.
 ---------------------------------------------------------------------------*)
GDPRComplianceInvariant ==
    \forall s \in Students :
        (offChainPII[s].status = "SHREDDED" \land ephemeralKey[s].isActive = FALSE) => isLinked[s] = FALSE

=============================================================================
