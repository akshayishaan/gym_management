# Gym Management

This context describes the domain language for managing a gym's members, memberships, plans, and payments.

## Language

**Membership lifecycle**:
The progression of a member's access through onboarding, plan purchase or renewal, and reversal of the latest qualifying payment. It excludes profile editing, soft deletion, and restoration.
_Avoid_: Membership sale, member CRUD

**Plan purchase**:
The assignment of a Plan that creates a Membership period, whether paid in full, partially, or not at the time of assignment. It never settles dues from an earlier Plan purchase.
_Avoid_: Membership payment

**Membership period**:
An inclusive sequence of calendar days during which a Member receives access from a Plan. The start date is the first active day and the expiry date is the final active day.
_Avoid_: Timestamp window

**Dues payment**:
A Payment applied only to a Member's existing outstanding balance. It does not create or extend a Membership period.
_Avoid_: Plan payment

**Void payment**:
An audit-preserving cancellation of a Payment that removes its accounting effect without removing an associated Membership period. The original Payment remains visible as voided.
_Avoid_: Delete payment

**Payment**:
An audit record created when staff records money received from a Member toward a Plan purchase or outstanding dues. It remains in the history if it is later voided or refunded.
_Avoid_: Invoice, promise to pay

**Refund**:
The return of money from a recorded Payment to a Member. It is distinct from voiding an entry that was recorded by mistake.
_Avoid_: Void, delete

**Plan purchase reversal**:
An audit-preserving cancellation of a Plan purchase that removes its Membership period and voids its associated Payment when one exists, restoring the Member's previous membership state.
_Avoid_: Delete membership payment

**Active Gym**:
The Gym currently selected by a staff member. It determines which tenant's records can be viewed or changed and which Gym settings are presented.
_Avoid_: Selected gym, current location

**Gym Insights**:
A point-in-time view of a Gym's revenue, payment activity, membership health, and Plan performance.
_Avoid_: Reports data, dashboard stats
