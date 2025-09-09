# 📱 BeaconAttendance iOS App Setup Guide

## ✅ Prerequisites
- Xcode 14.0 or later
- iOS 14.0+ deployment target
- Apple Developer account (for device testing)
- Physical iOS device (iBeacon doesn't work on simulator)

## 🚀 Quick Setup Steps

### 1. Create New Xcode Project
1. Open Xcode
2. File → New → Project
3. Choose **iOS → App**
4. Configure:
   - **Product Name**: BeaconAttendance
   - **Team**: Select your team
   - **Organization Identifier**: com.oxii (or your identifier)
   - **Bundle Identifier**: Will be `com.oxii.BeaconAttendance`
   - **Interface**: Storyboard
   - **Language**: Swift
   - **Use Core Data**: NO
   - **Include Tests**: Optional
5. Save to: `test_ble_ios/BeaconAttendanceProject` (new folder)

### 2. Delete Auto-Generated Files
Delete these files from the new project (we'll use our custom ones):
- `ViewController.swift`
- `Main.storyboard`
- `Assets.xcassets` folder
- `LaunchScreen.storyboard`
- `Info.plist`
- `AppDelegate.swift`
- `SceneDelegate.swift`

### 3. Add Our Custom Files
1. Right-click on project navigator → Add Files to "BeaconAttendance"
2. Navigate to `test_ble_ios/BeaconAttendanceApp`
3. Select the entire `BeaconAttendanceApp` folder
4. Options:
   - ✅ Copy items if needed
   - ✅ Create groups
   - ✅ Add to target: BeaconAttendance
5. Click Add

### 4. Add Swift Package Dependencies
1. Select project in navigator
2. Select project (not target) in editor
3. Go to **Package Dependencies** tab
4. Click **+** button
5. Click **Add Local...**
6. Navigate to `test_ble_ios` folder (the one with Package.swift)
7. Click **Add Package**
8. In the package products dialog:
   - ✅ BeaconAttendanceCore → Add to BeaconAttendance target
   - ✅ BeaconAttendanceFeatures → Add to BeaconAttendance target
9. Click **Add Package**

### 5. Configure Build Settings
1. Select the BeaconAttendance target
2. Go to **Build Settings** tab
3. Search for "Info.plist"
4. Set **Info.plist File** to: `BeaconAttendanceApp/Resources/Info.plist`

### 6. Configure Signing & Capabilities
1. Select the BeaconAttendance target
2. Go to **Signing & Capabilities** tab
3. Enable **Automatically manage signing**
4. Select your **Team**
5. Bundle Identifier should be `com.oxii.BeaconAttendance` (or your custom one)

### 7. Add Required Capabilities
Click **+ Capability** and add:
- ✅ **Background Modes**:
  - Uses Bluetooth LE accessories
  - Location updates
  - Background fetch
  - Background processing
- ✅ **Push Notifications** (if needed)

### 8. Update Swift Files to Import Packages
Open these files and uncomment the import statements:
1. `AppDelegate.swift`:
   ```swift
   import BeaconAttendanceCore
   import BeaconAttendanceFeatures
   ```
2. `AttendanceViewController.swift`:
   ```swift
   import BeaconAttendanceCore
   import BeaconAttendanceFeatures
   ```

### 9. Wire Up the Core Services (Optional)
In `AppDelegate.swift`, update `setupCoreServices()`:
```swift
private func setupCoreServices() {
    // Initialize lifecycle manager
    _ = AppLifecycleManager.shared
    
    // Register dependencies
    let userId = getUserId()
    DependencyContainer.registerAppDependencies(userId: userId)
    
    // Build services
    let services = CompositionRoot.build(
        baseURL: URL(string: "https://api.example.com")!,
        userId: userId
    )
    
    // Start monitoring
    let testSites = [
        SiteRegion(
            siteId: "HQ-Building-A",
            uuid: UUID(uuidString: "FDA50693-A4E2-4FB1-AFCF-C6EB07647825")!,
            major: 100
        )
    ]
    services.coordinator.start(sites: testSites)
}
```

## 🏃‍♂️ Build and Run

### On Simulator (Limited Testing)
1. Select an iPhone simulator
2. Click **Run** (▶️)
3. Note: iBeacon features won't work, but UI will be testable

### On Physical Device (Full Testing)
1. Connect your iPhone/iPad via USB
2. Select your device from the device list
3. Click **Run** (▶️)
4. Trust the developer certificate on device if prompted:
   - Settings → General → VPN & Device Management
   - Select your developer account
   - Tap "Trust"

## 🔍 Verify Setup

### Check These Work:
- [ ] App launches without crashing
- [ ] Navigation bar shows "Beacon Attendance"
- [ ] Status card displays
- [ ] Manual check-in button works
- [ ] Permissions prompts appear (location, notifications)

### For Real Testing:
- [ ] Have an iBeacon device ready
- [ ] Configure with UUID: `FDA50693-A4E2-4FB1-AFCF-C6EB07647825`
- [ ] Set Major: 100, Minor: Any
- [ ] Grant "Always Allow" location permission
- [ ] Move near/far from beacon to test detection

## 🐛 Troubleshooting

### "No such module" Error
- Make sure packages are properly added in Package Dependencies
- Clean build folder: Shift+Cmd+K
- Reset package caches: File → Packages → Reset Package Caches

### Signing Errors
- Ensure you have a valid Apple Developer account
- Select correct team in Signing & Capabilities
- Check bundle identifier is unique

### Beacon Not Detected
- Check beacon UUID matches exactly
- Ensure Bluetooth is ON
- Location permission must be "Always"
- Background App Refresh must be ON
- Try restarting the app

## 📝 Project Structure

```
BeaconAttendanceProject/
├── BeaconAttendance.xcodeproj
├── BeaconAttendanceApp/
│   ├── Sources/
│   │   ├── AppDelegate.swift
│   │   ├── SceneDelegate.swift
│   │   └── AttendanceViewController.swift
│   └── Resources/
│       ├── Info.plist
│       ├── LaunchScreen.storyboard
│       └── Assets.xcassets/
└── Packages/ (linked, not copied)
    ├── BeaconAttendanceCore
    └── BeaconAttendanceFeatures
```

## 🎉 Success!
You should now have a working iOS app with:
- Clean Hybrid architecture
- Modular Swift packages
- Beacon detection ready
- Professional UI
- Background monitoring support

Happy coding! 🚀
