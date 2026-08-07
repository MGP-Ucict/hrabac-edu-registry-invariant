------------------- MODULE SourceAuthenticity -------------------
EXTENDS Sequences, Integers

(*---------------------------------------------------------------------------
  CONSTANTS & TYPES DEFINITIONS
  AuthorizedUniversities: The bounded set of all accredited institutional nodes.
  Records: The bounded set of unique academic credential inputs for model checking.
 ---------------------------------------------------------------------------*)
CONSTANTS AuthorizedUniversities, Records

VARIABLES
    onChainState,       (* The set of globally committed hashes on the public ledger *)
    registeredUni,      (* Map representing the smart contract identity registry state *)
    networkPayload,     (* Inbound execution buffer representing transaction payloads *)
    ledgerHistory       (* Immutable archive tracking historical verified state transitions *)

vars == <<onChainState, registeredUni, networkPayload, ledgerHistory>>

(*---------------------------------------------------------------------------
  INITIAL SYSTEM STATE
  Establishes the foundational state invariants for all variables.
 ---------------------------------------------------------------------------*)
Init ==
    /\ onChainState = {}
    /\ registeredUni = [u \in AuthorizedUniversities |-> [isActive |-> TRUE]]
    /\ networkPayload = {}
    /\ ledgerHistory = {}

(*---------------------------------------------------------------------------
  ACTION: SignAndSubmit
  Models the off-chain cryptographic signature generation process. 
  An authorized university utilizes its private key to generate an 
  ECDSA signature payload for a specific academic record.
 ---------------------------------------------------------------------------*)
SignAndSubmit(uni, record) ==
    /\ uni \in AuthorizedUniversities
    /\ record \in Records
    /\ registeredUni[uni].isActive = TRUE
    (* Cryptographic broadcast adding the raw record and signature metadata to the pool *)
    /\ networkPayload' = networkPayload \cup {[payload |-> record, signature |-> uni]}
    /\ UNCHANGED <<onChainState, registeredUni, ledgerHistory>>

(*---------------------------------------------------------------------------
  ACTION: VerifyAndCommit
  Models the native execution layer of the on-chain smart contract.
  The EVM invokes low-level ecrecover validation. If the recovered public 
  address matches an active registered university, the state commits.
  If verification fails, an absolute EVM REVERT state-halt is triggered, 
  rolling back contract mutations while clearing the processed payload.
 ---------------------------------------------------------------------------*)
VerifyAndCommit ==
    \E tx \in networkPayload:
        LET recoveredAddress == tx.signature IN
        (* Enforces require(registeredUniversities[recoveredAddress].isActive) *)
        IF recoveredAddress \in AuthorizedUniversities \land registeredUni[recoveredAddress].isActive = TRUE
        THEN 
            /\ onChainState' = onChainState \cup {tx.payload}
            /\ networkPayload' = networkPayload \ {tx}  (* Clear from mempool pool *)
            /\ ledgerHistory' = ledgerHistory \cup {tx}  (* Permanently log for audit trail *)
            /\ UNCHANGED registeredUni
        ELSE 
            (* EVM REVERT: Contract modifications roll back, payload is dropped *)
            /\ networkPayload' = networkPayload \ {tx}
            /\ UNCHANGED <<onChainState, registeredUni, ledgerHistory>>

(*---------------------------------------------------------------------------
  NEXT-STATE RELATION
  Defines the permissible non-deterministic system transitions.
 ---------------------------------------------------------------------------*)
Next == 
    \/ VerifyAndCommit 
    \/ \E u \in AuthorizedUniversities, r \in Records : SignAndSubmit(u, r)

(*---------------------------------------------------------------------------
  FORMAL MATHEMATICAL SYSTEM INVARIANT
  Proof Verification Goal: Every committed state transition inside the public 
  ledger must map back to an authentic, uncompromised, and accredited 
  institution's private key archived within the system's ledger history.
 ---------------------------------------------------------------------------*)
SourceAuthenticityInvariant ==
    \forall committedRecord \in onChainState:
        \exists tx \in ledgerHistory:
            /\ tx.payload = committedRecord
            /\ tx.signature \in AuthorizedUniversities
            /\ registeredUni[tx.signature].isActive = TRUE

============================================================================
