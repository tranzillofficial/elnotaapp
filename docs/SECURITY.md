# ElNota | Security Requirements

## Threat model
Protect tenant financial data against cross-account leakage, stolen devices, compromised session tokens, forged sync requests, accidental administrator access and unreliable offline storage.

## Authentication and authorization
- Use Supabase Auth; store tokens using platform-appropriate secure storage when supported and tested.
- Apply **Row Level Security (RLS)** to every tenant-owned table. All read/write paths must enforce tenant membership and roles.
- Do not rely on hidden Flutter UI elements or client-side `workspace_id` checks for authorization.
- Privileged onboarding/activation, administrative overrides and webhook processing run server-side with authorization checks.
- On user switch/logout, clear cached session and segregate or erase decrypted user data on disk according to retention policy.

## Secrets and network
- Supabase **publishable/anon** client key is not a secret; secret/service-role keys must never appear in mobile/desktop binaries.
- Never include private API keys, passwords or tokens in repo, docs, screenshots, logs, backups or telemetry.
- Use TLS; validate server-side webhook signatures/verification per provider docs.
- Do not trust payment success redirects as proof of payment; verify independently before activation.

## Offline data
- SQLite is **not encrypted by default**. Assess threat model and choose tested encrypted-at-rest storage/key management before storing sensitive customer financial data on lost/stolen devices.
- Prevent cross-user cached-data leakage on shared computers.
- Backups must be encrypted and restorable; protect and rotate encryption keys; never silently upload customer data to consumer cloud storage.
- Biometrics/PIN are optional local unlock safeguards, **not** substitutes for Supabase authorization.

## Financial integrity
- Validate amounts, permissions and state transitions on the server, not only Flutter.
- Use idempotent, append-only financial events, audit trails, and server-controlled authorization.
- Record actor, timestamp, entity and approved reason for reversals/discounts.

## Privacy & governance
- Collect only necessary personal details; publish an understandable privacy policy and data deletion/contact process.
- Provide minimal role-based access to staff/admins; audit high-risk actions.
- Define retention, backup recovery and incident response before public rollout.
- Consider app-store requirements for privacy disclosure and account deletion where applicable.

## Review checklist
- [ ] RLS membership tests pass for own workspace, other workspace, unauthenticated access.
- [ ] Secrets scan clean; `.env` values appropriately separated, no server secrets in client.
- [ ] Device at-rest protection and logout behavior verified on Android/iOS/Windows.
- [ ] Payment activation verifies trusted webhook/source and is replay safe.
- [ ] Sensitive logs redact PII, financial details and auth tokens.
- [ ] User data export/deletion and backup restoration tested.
