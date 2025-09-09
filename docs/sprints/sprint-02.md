# Sprint 02 — Exit, Soft‑Exit & Heartbeat (2 weeks)

## Goals
- Implement `didExit` flow, soft‑exit prediction + grace, `checkOut`, `heartbeat`

## Stories & Tasks
1. **PresenceStateMachine**
   - States & timers; soft‑exit triggers; `requestState(for:)` validation
2. **Checkout Pipeline**
   - Commit on `didExit` or validated soft‑exit post‑grace
3. **Heartbeat**
   - Opportunistic (display wake, enter, periodic safe window) via background session
4. **Idempotency & Backoff**
   - Exponential backoff, dedupe, crash‑safe queue
5. **Metrics**
   - Exit latency, false‑exit rate, retry counts

## Acceptance Criteria
- No false checkout during brief RSSI dips (< 10s)
- Exit is recorded within median ≤ 50s after leaving
- Sessions always closed eventually via TTL if client misses exit
