----------------------- MODULE HrabacInvariant4 -----------------------
EXTENDS Naturals, Sequences

CONSTANTS 
    Students,       \* Set of abstract student identifiers
    Diplomas        \* Set of 32-byte cryptographic diploma hashes

VARIABLES 
    offchainPII,            \* Maps Student -> [Name, NationalID, SecretSalt] or NULL
    deactivatedStudents,    \* On-chain mapping state: Student -> BOOLEAN (Blacklist Layer)
    cryptoAnchors           \* On-chain ledger layer: Diplomas -> (Student -> BOOLEAN)

vars == <<offchainPII, deactivatedStudents, cryptoAnchors>>

-----------------------------------------------------------------------------
\* --- INITIAL SYSTEM STORAGE LAYOUT ---
Init == 
    /\ offchainPII = [s \in Students |-> "ActivePII"]
    /\ deactivatedStudents = [s \in Students |-> FALSE]
    /\ cryptoAnchors = [d \in Diplomas |-> [s \in Students |-> FALSE]]

-----------------------------------------------------------------------------
\* --- STATE TRANSITIONS / SOLIDITY OPERATIONS ---

\* Simulates regular credential ingestion (emitEpochState)
EmitCredential(s, d) ==
    /\ deactivatedStudents[s] = FALSE
    /\ offchainPII[s] /= "SHREDDED"
    /\ cryptoAnchors' = [cryptoAnchors EXCEPT ![d][s] = TRUE]
    /\ UNCHANGED <<offchainPII, deactivatedStudents>>

\* Simulates: setStudentDeactivatedStatus(_citizenHash, true) + Off-chain Shredding
ExecuteGDPRErasure(s) ==
    /\ deactivatedStudents[s] = FALSE  \* Guard: Can only erase active subjects
    /\ deactivatedStudents' = [deactivatedStudents EXCEPT ![s] = TRUE]
    /\ offchainPII' = [offchainPII EXCEPT ![s] = "SHREDDED"]
    /\ UNCHANGED cryptoAnchors

\* Bypasses the parser deadlock bug when all actions are completed
IdleLoop ==
    /\ \A s \in Students : deactivatedStudents[s] = TRUE
    /\ UNCHANGED vars

-----------------------------------------------------------------------------
Next == 
    \/ \exists s \in Students, d \in Diplomas : EmitCredential(s, d)
    \/ \exists s \in Students : ExecuteGDPRErasure(s)
    \/ IdleLoop

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\* 🛡️ FORMAL DEFINITION OF INVARIANT 4 (GDPR COMPLIANCE & ANONYMIZATION)
-----------------------------------------------------------------------------
Invariant4 == 
    \A s \in Students : 
        deactivatedStudents[s] = TRUE => 
            /\ offchainPII[s] = "SHREDDED"

=============================================================================
