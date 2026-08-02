------------------- MODULE GDPRCompliance -------------------
EXTENDS Sequences, Integers

(*---------------------------------------------------------------------------
  CONSTANTS DEFINITIONS
  Students: The set of unique student identities.
  PlaintextPII: The sensitive personally identifiable metadata.
 ---------------------------------------------------------------------------*)
CONSTANTS Students, PlaintextPII

VARIABLES
    offChainPII,       (* The set of localized append-only database tier *)
    ephemeralKey,      (* The state of the Ephemeral_Key_Registry (Symmetric keys) *)
    onChainHash,       (* The immutable public blockchain data slot ledger *)
    isLinked           (* Dynamic safety tracking mapping to monitor data linkability *)

(*---------------------------------------------------------------------------
  INITIAL SYSTEM STATE
 ---------------------------------------------------------------------------*)
Init ==
    /\ offChainPII = [s \in Students |-> [pii |-> CHOOSE p \in PlaintextPII : TRUE, status |-> "ACTIVE"]]
    /\ ephemeralKey = [s \in Students |-> [key |-> "ValidKey32Bytes", isActive |-> TRUE]]
    /\ onChainHash = [s \in Students |-> "ImmutableKeccak256Hash"]
    /\ isLinked = [s \in Students |-> TRUE]

(*---------------------------------------------------------------------------
  ACTION: ExecuteGDPRRightToForget
  Models the infrastructure-enforced cryptographic shredding routine.
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
    /\ UNCHANGED <<offChainPII, ephemeralKey, onChainHash, isLinked>>

(*---------------------------------------------------------------------------
  NEXT-STATE RELATION
 ---------------------------------------------------------------------------*)
Next ==
    \/ \E s \in Students : ExecuteGDPRRightToForget(s)
    \/ Idle

(*---------------------------------------------------------------------------
  FORMAL MATHEMATICAL SYSTEM INVARIANT (INVARIANT 4)
 ---------------------------------------------------------------------------*)
GDPRComplianceInvariant ==
    \forall s \in Students :
        (offChainPII[s].status = "SHREDDED" \land ephemeralKey[s].isActive = FALSE) => isLinked[s] = FALSE

=============================================================================
