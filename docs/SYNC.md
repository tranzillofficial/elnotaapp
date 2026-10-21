# ElNota | Offline Sync Protocol

> Design specification. Sync is a reliability-critical subsystem, not a connectivity callback.

## Guarantees / non-guarantees
- UI reads and writes Drift first. All domain changes + outbox operation stored **atomically**.
- Network delivery is at least once; server processing is **idempotent**, keyed by stable `operation_id`.
- Do not claim guaranteed background execution on iOS or Windows. The next foreground sync must catch up.
- Server reconciliation is authoritative for shared data; finance operations must not silently overwrite each other.

## Local operation envelope
```json
{
  "operation_id":"uuid",
  "workspace_id":"uuid",
  "entity_type":"payment",
  "entity_id":"uuid",
  "action":"create",
  "base_version":0,
  "schema_version":1,
  "created_at_client":"ISO-8601",
  "payload":{}
}
```
`operation_id` stays unchanged during retry. Do not use client timestamps as ordering authority.

## Push pipeline
1. Begin Drift transaction: validate domain operation, write record/ledger entries, enqueue outbox row.
2. Worker claims pending rows (avoid concurrent workers / duplicate claims locally).
3. Send small batches over authenticated HTTPS to server RPC/Edge Function.
4. Server validates RLS authorization, versions, legal state transitions and idempotency key; commits atomically.
5. Server returns per-operation `accepted | duplicate | conflict | rejected`, authoritative version and stable error code.
6. Mark acknowledged ops and update local records in a Drift transaction. Retain actionable errors for UI/support.
7. Retry transient errors with capped exponential backoff + jitter. **Never** blindly retry validation failures.

## Pull pipeline
- Request changes after a **server-issued monotonically ordered cursor** per workspace (not device wall-clock `updated_at`).
- Return tombstones and access revocations; paginate in deterministic order.
- Apply page and cursor in one Drift transaction so crash/restart can't lose entries.
- A full rebase/reconciliation path handles expired cursors, corrupted state and membership changes.
- On logout/account switching, clear or securely isolate prior user's on-device data; do not mix workspaces.

## Conflict policy
| Data | Conflict approach |
|---|---|
| UI settings | per-field version or last writer only if explicitly acceptable |
| Customer contact fields | optimistic version; user chooses on conflict |
| Products | optimistic version; merge only disjoint fields |
| Payments, invoices, financial ledger | **no blind merge / no last-write-wins**; append-only posted operations, idempotency and authoritative corrections |
| Deletes | tombstone + referential restrictions + audit trail |

## Financial invariants
- A payment UUID is processed once even if the client retries after timeout.
- Customer-level payment reduces the customer's **overall** balance, not a chosen invoice unless product explicitly introduces allocations.
- If offline writes collide with server validation (deleted account, revoked membership, changed currency), mark as `needs_attention`, don't silently discard.
- Money changes must remain traceable by user/device/operation and reversal event.

## Trigger matrix
- App startup and resume: sync after session validation.
- Successful local mutation: enqueue now, opportunistically sync.
- Network reconnect: retry if reachability/credentials confirmed (connectivity alone isn't proof).
- Foreground periodic interval: optional best-effort; throttle to conserve battery/network.
- Background jobs: best-effort only; never rely on midnight exact execution.

## Recommended outbox states
`pending -> sending -> acknowledged`; transient failure `-> pending`, business failure `-> needs_attention`. Recover stale `sending` jobs after app crash.

## Test cases
- Offline create -> app killed -> restart -> reconnect.
- Server commits but response lost -> retry -> exactly one payment.
- Concurrent two-device payment submissions.
- Delete customer with financial history.
- Schema migration while offline and queued writes pending.
- 401 refresh, permission revocation, expired sync cursor, partial batches and paging boundaries.
- Device clock skew, duplicate page fetch, thousands of records, low-storage conditions.

## Logging and observability
Log anonymized operation IDs, result codes, retry counts and sync lag. Avoid logging customers' names, credentials, complete financial payloads or secrets.
