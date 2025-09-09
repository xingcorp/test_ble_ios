# Server Contracts (Minimal)

## Endpoints
- `POST /attendance/check-in`
- `POST /attendance/check-out`
- `POST /attendance/heartbeat`

## Common fields
- `userId`, `siteId`, `ts` (ISO8601), `sessionKey`, `deviceMeta { os, appVersion, model }`

## Behavior
- **Idempotent** by `sessionKey`
- Enforce **TTL** auto‑checkout after X minutes silence; label reason `timeout`
- Return `sessionKey` and server timestamps; include `retryAfter` hints
