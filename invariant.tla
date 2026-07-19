------------------- MODULE HRABAC_Recovery -------------------
EXTENDS Integers, Sequences

CONSTANT Snapshots   \* Only Snapshots remains as a constant

\* Define Blockchain locally as a fixed sequence
Blockchain == <<"Snapshot_Jan", "Snapshot_Feb", "Snapshot_March_Clean">>

VARIABLES 
    current_db,       
    selected_snapshot,
    system_status     

Init ==
    /\ current_db \in Snapshots
    /\ selected_snapshot = "None"
    /\ system_status = "Operational"

CorruptDatabase ==
    /\ system_status = "Operational"
    /\ current_db' \in Snapshots \ {current_db}  
    /\ system_status' = "Corrupted"
    /\ UNCHANGED <<selected_snapshot>>

ExecuteRecovery ==
    /\ system_status = "Corrupted"
    /\ \E s \in Snapshots :
          /\ \E idx \in 1..Len(Blockchain) : Blockchain[idx] = s  
          /\ selected_snapshot' = s
    /\ current_db' = selected_snapshot'
    /\ system_status' = "Recovered"

Next == CorruptDatabase \/ ExecuteRecovery

Spec == Init /\ [][Next]_<<current_db, selected_snapshot, system_status>>

RecoveryStateInvariant ==
    (system_status = "Recovered") => (current_db = selected_snapshot /\ \E idx \in 1..Len(Blockchain) : Blockchain[idx] = current_db)
==============================================================
