# Sprint 01 — Bootstrap & Enter Pipeline (2 weeks)

## Goals
- Setup project/workspace, Info.plist, permissions UX
- Implement `didEnter` → ranging burst → nearest site → `checkIn`

## Stories & Tasks
1. **Project Skeleton & Modules**
   - Create Xcode workspace + SwiftPM modules (`Core`, `Features`)
   - Add lint/format (SwiftLint), CI basic build
2. **Permissions & Onboarding**
   - Request When‑In‑Use → upgrade to Always; education screens for Background App Refresh
3. **BeaconRegionManager**
   - Register regions per site (UUID + major), set notifications
   - Handle app launch from region events
4. **ShortRanger + RSSI smoothing**
   - Time‑boxed ranging 5–10s, MA window, nearest beacon/site
5. **AttendanceAPI + Background URLSession**
   - `checkIn` idempotent; queue & retry
6. **Basic Telemetry**
   - Structured logs for enter/ranging/check‑in

## Acceptance Criteria
- Enter near a site wakes the app (terminated OK) and completes `checkIn` ≤ 10s
- Ranging burst stops on time; battery baseline not worse than +2%/day in limited tests

## DoD
- Unit tests for ranger timeout & MA
- Manual test plan executed on at least 2 devices (A/B iOS versions)
