# Phase 2 — Core Architecture & Folder Structure

## Mục tiêu
- Dựng skeleton kiến trúc, module hoá theo chuẩn app lớn, tối ưu cho background/terminated.

## Folder Structure (proposal)

```
Sources/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── CompositionRoot.swift
├── Core/
│   ├── Beacon/
│   │   ├── BeaconRegionManager.swift
│   │   ├── ShortRanger.swift
│   │   ├── RSSISmoother.swift
│   │   └── PresenceStateMachine.swift
│   ├── Location/
│   │   ├── SLCSService.swift
│   │   └── GeofenceService.swift
│   ├── Networking/
│   │   ├── BackgroundURLSessionClient.swift
│   │   ├── AttendanceAPI.swift
│   │   └── IdempotencyKeyProvider.swift
│   ├── Persistence/
│   │   └── Store.swift (CoreData/SQLite wrapper)
│   ├── Models/
│   │   ├── Session.swift
│   │   ├── Site.swift
│   │   └── TelemetryEvent.swift
│   ├── Observability/
│   │   ├── Logger.swift
│   │   └── Metrics.swift
│   └── Utils/
│       ├── DateProvider.swift
│       ├── Debouncer.swift
│       └── RetryPolicy.swift
├── Features/
│   └── Attendance/
│       ├── AttendanceController.swift
│       ├── AttendanceRepository.swift
│       └── AttendanceViewModels.swift
├── Resources/
│   └── Info.plist
└── Tests/
    ├── Unit/
    ├── Integration/
    └── UI/
```

## Thành phần chính
- **BeaconRegionManager**: đăng ký `CLBeaconRegion` theo site (UUID + major), bật `notifyOnEntry/Exit` + `notifyEntryStateOnDisplay`, forward events.
- **ShortRanger**: `startRangingBeacons` với `CLBeaconIdentityConstraint`, timeout 5–10s, trả nearest + RSSI MA.
- **PresenceStateMachine**: `ENTER → INSIDE → SOFT_EXIT_PENDING → EXIT`; quản lý grace, timers, confirm bằng `requestState(for:)`.
- **BackgroundURLSessionClient**: cấu hình session background, enqueue `checkIn/checkOut/heartbeat`, idempotent theo `sessionKey`.
- **AttendanceAPI**: DTO + retry/backoff, tiêu chuẩn hoá lỗi.
- **SLCSService/GeofenceService**: safety nets kích hoạt re-evaluation khi di chuyển xa.

## Contracts tối thiểu (server)
- `POST /attendance/check-in { userId, siteId, ts, sessionKey, deviceMeta }`
- `POST /attendance/check-out { sessionKey, ts, reason }`
- `POST /attendance/heartbeat { sessionKey, ts }`
- Tất cả **idempotent** theo `sessionKey`.

## Acceptance Criteria (Core)
- Nhận `didEnter/Exit` khi app **terminated** (không force‑quit), xử lý check‑in/out trong **≤ 10s**.
- Không miss entry/exit khi người dùng cấp **Always** + **Background App Refresh**.
- Soft‑exit không tạo **false checkout** trong trường hợp nhiễu ngắn (< 10s).
- Network queue sống sót qua app relaunch/crash.
