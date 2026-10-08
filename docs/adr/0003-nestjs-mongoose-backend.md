# Backend is NestJS + Mongoose, not Django, DB stays MongoDB

The migration originally specified Python/Django, but we chose NestJS (TypeScript) + Mongoose as the backend, keeping the existing MongoDB Atlas cluster. NestJS uses the same language, ODM, and runtime as today's Next.js backend, so `lib/membershipLifecycle.ts`, `lib/memberLedger.ts`, and `lib/gymInsights.ts` port almost verbatim — no data migration, no aggregation rewrite, no ORM translation. This makes "no business logic change" directly auditable line-by-line.

Status: accepted
Considered Options: Python/Django (rejected — different language and ODM would require rewriting the Mongoose aggregation pipelines and transaction logic); FastAPI (rejected — same problem). PostgreSQL was also floated and rejected to honor the "same DB, no logic change" constraint.
