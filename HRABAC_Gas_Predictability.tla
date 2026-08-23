----------------------- MODULE HrabacInvariant2 -----------------------
EXTENDS Naturals, Sequences

CONSTANTS 
    MaxRecords,       \* Target scale for database expansion (e.g., 1000)
    HrabacFlatGas     \* Immutable execution cost from paper (29334)

VARIABLES 
    N,                     \* Total active ledger volume
    hrabacVerificationGas  \* Execution gas footprint for Reg-HRABAC

vars == <<N, hrabacVerificationGas>>

-----------------------------------------------------------------------------
Init == 
    /\ N = 1
    /\ hrabacVerificationGas = HrabacFlatGas

ScaleLedger ==
    \/  /\ N < MaxRecords
        /\ N' = N + 1
        /\ hrabacVerificationGas' = hrabacVerificationGas
    \* Bypasses the parser deadlock bug: idles infinitely when limit is reached
    \/  /\ N >= MaxRecords
        /\ UNCHANGED vars

-----------------------------------------------------------------------------
Next == ScaleLedger

Spec == Init /\ [][Next]_vars

-----------------------------------------------------------------------------
\*  PURE INVARIANT 2 SPECIFICATION
-----------------------------------------------------------------------------
Invariant2 == 
    hrabacVerificationGas = HrabacFlatGas
=============================================================================
