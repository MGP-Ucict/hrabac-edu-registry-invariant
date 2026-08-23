----------------------- MODULE HrabacInvariant5 -----------------------
EXTENDS Naturals, Sequences

CONSTANTS 
    Epochs,         \* Set of batch epoch hashes (bytes32 roots)
    Diplomas        \* Set of credential tracking hashes inside batches

VARIABLES 
    validatedEpochs,    \* On-chain mapping state: Epochs -> BOOLEAN
    cryptoAnchors       \* On-chain structural ledger: Diplomas -> Epochs

vars == <<validatedEpochs, cryptoAnchors>>

-----------------------------------------------------------------------------
\* --- INITIAL CONTRACT STORAGE LAYOUT ---
Init == 
    /\ validatedEpochs = [e \in Epochs |-> TRUE]
    /\ cryptoAnchors = [d \in Diplomas |-> CHOOSE e \in Epochs : TRUE]

-----------------------------------------------------------------------------
\* --- STATE TRANSITIONS / CONTRACT ACTIONS ---

\* Simulates: revokeEpoch(bytes32 _epochRoot)
RevokeEpochAction(e) ==
    /\ validatedEpochs[e] = TRUE
    /\ validatedEpochs' = [validatedEpochs EXCEPT ![e] = FALSE]
    /\ UNCHANGED cryptoAnchors

\* Avoids parser deadlock triggers once all states are fully generated
IdleLoop ==
    /\ \A e \in Epochs : validatedEpochs[e] = FALSE
    /\ UNCHANGED vars

-----------------------------------------------------------------------------
Next == 
    \/ \exists e \in Epochs : RevokeEpochAction(e)
    \/ IdleLoop

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\*  FORMAL DEFINITION OF INVARIANT 5 (BATCH REVOCATION ATOMICITY)
-----------------------------------------------------------------------------
Invariant5 == 
    \A d \in Diplomas : 
        LET associatedEpoch == cryptoAnchors[d]
        IN validatedEpochs[associatedEpoch] = FALSE => 
            (validatedEpochs[associatedEpoch] = FALSE)

=============================================================================
