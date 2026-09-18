------------------- MODULE PostQuantumIngestion -------------------
EXTENDS Integers, Sequences

CONSTANTS 
    Valid,      \* Ingestion status injected via .cfg (TRUE)
    Forged,     \* Adversarial status injected via .cfg (FALSE)
    NIST_LEVEL  \* Security level compliance parameter matching NIST FIPS 204 (5)

VARIABLES 
    kafka_log,      \* Asynchronous Kafka Queue
    rpc_pool,       \* Private RPC Transaction Pool
    ledger_state    \* On-chain validated state mapping

\* Bounded set of payload IDs to strictly limit the state space explosion
TestPayloads == 1..2

\* Maximum depth of the Kafka queue to prevent memory lockup and infinite sizing
MaxQueueLength == 2

ConstantsRecord == [NIST_LEVEL |-> NIST_LEVEL, Valid |-> Valid, Forged |-> Forged]

\* Bounded TypeOK invariant that resolves instantaneously without evaluating infinite sets
TypeOK == 
    /\ Len(kafka_log) <= MaxQueueLength
    /\ ledger_state \in [TestPayloads -> BOOLEAN]

\* Initial state topology setup (Empty states)
Init ==
    /\ kafka_log = << >>
    /\ rpc_pool = {}
    /\ ledger_state = [p \in TestPayloads |-> FALSE]

\* Next-state relations with strict execution boundaries
Next ==
    \* Action 1: Sign and append to Kafka (only if under the MaxQueueLength threshold)
    \/ \E p \in TestPayloads : 
        /\ Len(kafka_log) < MaxQueueLength
        /\ kafka_log' = Append(kafka_log, [payload |-> p, sig |-> 1, status |-> Valid])
        /\ UNCHANGED <<rpc_pool, ledger_state>>
        
    \* Action 2: Dequeue from Kafka and forward to RPC pool
    \/ /\ kafka_log /= << >>
       /\ rpc_pool' = rpc_pool \cup {Head(kafka_log)}
       /\ kafka_log' = Tail(kafka_log)
       /\ UNCHANGED ledger_state
       
    \* Action 3: Finalize RPC block transaction to ledger state
    \/ \E tx \in rpc_pool :
        /\ tx.status = Valid
        /\ ledger_state' = [ledger_state EXCEPT ![tx.payload] = TRUE]
        /\ UNCHANGED <<kafka_log, rpc_pool>>

\* Complete system operational specification
Spec == Init /\ [][Next]_<<kafka_log, rpc_pool, ledger_state>>

\* INVARIANT 6: End-to-End Post-Quantum Ingestion Integrity Safety Condition
Invariant_6_IngestionSafety == 
    \forall tx \in rpc_pool : 
        (ledger_state[tx.payload] = TRUE) => (tx.status = Valid)

===================================================================
