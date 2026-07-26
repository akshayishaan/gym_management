---
status: accepted
---

# Make Membership lifecycle mutations transactional

Membership lifecycle mutations write Member, Payment, Membership, derived ledger state, and ActivityLog records. These writes must run in a MongoDB transaction so they commit or abort together; requiring replica-set transaction support is preferred over best-effort compensation because partial state can corrupt membership access, accounting, and the audit trail. Local Docker and production MongoDB must therefore support transactions, and lifecycle writes must not bypass the transaction.
