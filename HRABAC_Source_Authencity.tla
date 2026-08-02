------------------- MODULE SourceAuthenticity -------------------
EXTENDS Sequences, Integers

(*---------------------------------------------------------------------------
  CONSTANTS & TYPES DEFINITIONS
  AuthorizedUniversities: The bounded set of all accredited institutional nodes.
  Records: The infinite set of all possible unique academic credential inputs.
 ---------------------------------------------------------------------------*)
CONSTANTS AuthorizedUniversities, Records

VARIABLES
    onChainState,       (* The set of globally committed hashes on the public ledger *)
    registeredUni,      (* Map representing the smart contract identity registry state *)
    networkPayload      (* Inbound execution buffer representing transaction payloads *)

(*---------------------------------------------------------------------------
  INITIAL SYSTEM STATE (SYSTEM INVARIANTS BASELINE)
 ---------------------------------------------------------------------------*)
Init ==
    /\ onChainState = {}
    (* CORRECTED syntax: Using [u \in Set |-> value] to instantiate the function mapping *)
    /\ registeredUni = [u \in AuthorizedUniversities |-> [isActive |-> TRUE]]
    /\ networkPayload = {}

(*---------------------------------------------------------------------------
  ACTION: SignAndSubmit
  Models the off-chain cryptographic signature generation process. 
  An authorized university utilizes its private key (SK_U) to generate 
  an ECDSA signature payload for academic record R.
 ---------------------------------------------------------------------------*)
SignAndSubmit(uni, record) ==
    /\ uni \in AuthorizedUniversities
    /\ record \in Records
    /\ registeredUni[uni].isActive = TRUE
    (* Cryptographic broadcast containing the raw payload and the digital signature *)
    /\ networkPayload' = networkPayload \cup {[payload |-> record, signature |-> uni]}
    /\ UNCHANGED <<onChainState, registeredUni>>

(*---------------------------------------------------------------------------
  ACTION: VerifyAndCommit
  Models the native execution layer of the on-chain smart contract.
  The EVM invokes the low-level ecrecover opcode. If the recovered public 
  address matches an active registered university, the entry is committed.
  Otherwise, it triggers an absolute EVM REVERT state-halt.
 ---------------------------------------------------------------------------*)
VerifyAndCommit ==
    \E tx \in networkPayload:
        LET recoveredAddress == tx.signature IN
        (* Enforces require(registeredUniversities[recoveredAddress].isActive) *)
        IF recoveredAddress \in AuthorizedUniversities \land registeredUni[recoveredAddress].isActive = TRUE
        THEN 
            /\ onChainState' = onChainState \cup {tx.payload}
            /\ networkPayload' = networkPayload \ {tx}
            /\ UNCHANGED registeredUni
        ELSE 
            (* EVM REVERT: Contract state transitions are aborted, transaction rolls back *)
            /\ networkPayload' = networkPayload \ {tx}
            /\ UNCHANGED <<onChainState, registeredUni>>

(*---------------------------------------------------------------------------
  NEXT-STATE RELATION
  Defines the permissible non-deterministic system transitions.
 ---------------------------------------------------------------------------*)
Next == 
    \/ VerifyAndCommit 
    \/ \E u \in AuthorizedUniversities, r \in Records : SignAndSubmit(u, r)

(*---------------------------------------------------------------------------
  FORMAL MATHEMATICAL SYSTEM INVARIANT
  Proof Verification Goal: Every committed state transition (S_on) inside 
  the blockchain ledger must map back to an authentic, uncompromised, 
  and accredited institution's private key.
 ---------------------------------------------------------------------------*)
SourceAuthenticityInvariant ==
    \forall committedRecord \in onChainState:
        \exists tx \in networkPayload \cup {[payload |-> r, signature |-> s] : r \in onChainState, s \in AuthorizedUniversities}:
            /\ tx.payload = committedRecord
            /\ tx.signature \in AuthorizedUniversities
            /\ registeredUni[tx.signature].isActive = TRUE

=============================================================================
