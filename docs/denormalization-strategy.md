# Denormalization Strategy

## Overview

This project uses intentional denormalization for audit-trail integrity. Certain fields are copied from their source documents to related documents at creation time, and are **not** updated if the source changes later.

## Denormalized Fields

| Source → Target | Field | Rationale |
|---|---|---|
| `Member.name` → `Payment.memberName` | `memberName` | Historical payments must show the member name at time of payment, even if member later changes name |
| `Plan.name` → `Payment.planName` | `planName` | Historical payments must show the plan name at time of payment, even if plan is renamed/deleted |
| `Plan.name` → `Member.planName` | `planName` | Member's current plan name is cached for fast list queries without joins; updated when member changes plan |
| `Staff.name` → `ActivityLog.staffName` | `staffName` | Activity logs must show who performed the action even if staff is later deactivated/deleted |

## Design Decisions

1. **Payments are immutable audit records** — Once a payment is recorded, its `memberName` and `planName` should never change, even if the member or plan is renamed. This preserves the financial audit trail.

2. **Member.planName is a cache** — This is updated when a member's plan changes (via PUT `/api/members/[id]`). It exists to avoid requiring a join/populate on every member list query. If a plan is renamed, existing members will still show the old plan name until they are explicitly updated.

3. **Activity logs are append-only** — `staffName` is captured at log creation time. If a staff member changes their name, old logs retain the original name. This is intentional for accountability.

## Future Considerations

- If plan renaming becomes common and showing stale names on members is unacceptable, add a migration script or a post-rename hook that updates `Member.planName` for all members with the old plan name.
- If member name changes need to propagate to historical payments, add an optional "backfill" admin action (not recommended for audit integrity).
