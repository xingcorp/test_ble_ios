# Beacon Attendance iOS - Production Ready

## 🎯 Overview

Production-grade **Beacon Attendance** app for iOS using **Core Location (iBeacon Region Monitoring)** with strong guarantees for **background/terminated** operation.

### ✅ Features
- ✅ Check-in/out with iBeacon detection
- ✅ Works in background/terminated state (not force-quit)
- ✅ Soft-exit with grace period (45s)
- ✅ RSSI smoothing with moving average
- ✅ Heartbeat service with smart scheduling
- ✅ Telemetry & monitoring system
- ✅ Offline-first with local notifications
- ✅ Battery optimized

### 📱 Hardware Requirements
- iBeacon UUID: `FDA50693-0000-0000-0000-290995101092`
- Major: fixed per physical beacon/site
- Minor: **rotates** (not used for identification)

## 🚀 Quick Start

### Prerequisites
- Xcode 14.0+
- iOS 14.0+ device (physical device required for iBeacon)
- Swift 5.7+
- iBeacon hardware for testing

### Installation

1. **Clone the repository**
```bash
git clone <repo-url>
cd test_ble_ios
```

2. **Generate Xcode project**
```bash
./generate_xcode_project.sh
```

3. **Open in Xcode**
```bash
open BeaconAttendance.xcodeproj
```

4. **Configure signing**
- Select your development team
- Update bundle identifier if needed

5. **Build and run**
- Select physical device (not simulator)
- Build and run (⌘R)

## 🏗️ Architecture

### Core Components

```
Sources/
├── Core/
│   ├── Beacon/          # iBeacon management
│   ├── Attendance/      # Check-in/out logic
│   ├── Services/        # Heartbeat, SLCS
│   ├── Networking/      # Background URLSession
│   ├── Telemetry/       # Monitoring & logs
│   ├── Constants/       # Centralized constants
│   ├── Errors/          # Error types
│   ├── DI/              # Dependency injection
│   └── Validation/      # Input validation
├── Features/
│   └── Attendance/      # Coordinator
└── App/
    ├── AppDelegate.swift
    └── CompositionRoot.swift
```

### Key Design Patterns
- **SOLID Principles** throughout
- **Dependency Injection** via container
- **Observer Pattern** for lifecycle
- **State Machine** for presence tracking
- **Repository Pattern** for data

## 📋 Configuration

### Required Permissions (Info.plist)
- `NSLocationAlwaysAndWhenInUseUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- `NSBluetoothAlwaysUsageDescription`

### Background Modes
- Location updates
- Background fetch
- Remote notifications (optional)

## 🧪 Testing

### Test Checklist
1. ✅ App terminated → beacon enter → check-in notification
2. ✅ Walk away from beacon → check-out notification (≤60s)
3. ✅ Brief signal loss → no false checkout (grace period)
4. ✅ Multiple beacons at site → stable presence
5. ✅ Force quit → no tracking (iOS limitation)

### Field Test Requirements
- Physical iOS device (14.0+)
- iBeacon with correct UUID
- "Always" location permission
- Background App Refresh ON

## 📊 Monitoring

### Telemetry Events
- Check-in/out events
- Region enter/exit
- Ranging sessions
- Heartbeats
- Errors with context

### Export Logs
```swift
let logURL = TelemetryManager.shared.exportLogs()
// Share via AirDrop or upload
```

## ⚠️ Known Limitations

1. **Force Quit**: If user force-quits app, tracking stops until manual relaunch
2. **20 Regions**: iOS limits to 20 monitored regions per app
3. **Simulator**: iBeacon doesn't work on simulator
4. **Battery**: Continuous ranging drains battery (we use bursts)

## 🔧 Troubleshooting

| Issue | Solution |
|-------|----------|  
| No check-in notification | Verify beacon UUID/Major, check permissions |
| Delayed check-out | Normal (30-60s), iOS region exit delay |
| Battery drain | Check ranging isn't continuous, verify heartbeat intervals |
| App crashes | Check device logs, export telemetry |

## 📚 Documentation

- [Phase 1 Overview](docs/phase-1-overview.md)
- [Core Architecture](docs/phase-2-core-architecture.md)
- [Sprint Plans](docs/sprints/sprint-plan.md)
- [Field Test Guide](docs/qa/field-test-checklist.md)
- [API Contracts](docs/ops/server-contracts.md)

## 🤝 Contributing

1. Create feature branch
2. Make changes (follow SOLID principles)
3. Add tests
4. Update documentation
5. Submit PR

## 📄 License

Proprietary - All rights reserved

## 👨‍💻 Team

Senior iOS Team - BeaconAttendance Project
