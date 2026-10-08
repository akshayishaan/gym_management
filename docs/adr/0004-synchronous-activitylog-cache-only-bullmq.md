# ActivityLog stays synchronous; BullMQ is scoped to cache invalidation only

The audit trail (`ActivityLog`) remains written synchronously inside the mutation transaction, exactly as today, so a mutation cannot commit without its log entry. We rejected the earlier plan to offload ActivityLog writes to BullMQ: a queued (eventually-written, possibly-dropped) audit record is a behavioral change to the write path, which "no business logic change" protects. BullMQ is kept but scoped strictly to non-critical side-effects — Redis cache invalidation — run asynchronously after the transaction commits. Expiry reminders are deferred to a future feature ticket (they don't exist in the app today and would introduce new user-visible behavior plus provider/messaging decisions outside migration scope).

Status: accepted
Considered Options: Queueing ActivityLog writes for lower latency (rejected — weakens audit-track guarantee); dropping BullMQ entirely (rejected — kept for cache invalidation; fast writes come from Redis read-caching + correct indexes, not from a queue).
