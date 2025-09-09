# Info.plist Configuration Guide

Add the following keys to your Info.plist file:

## Required Permissions

```xml
<!-- Location Permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to track your attendance at work sites using Bluetooth beacons.</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>This app needs Always location access to automatically check you in/out when you arrive/leave work sites, even when the app is closed.</string>

<!-- Optional: If using CoreBluetooth for additional features -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to detect nearby beacons for attendance tracking.</string>
```

## Background Modes

Enable in Xcode project settings under "Signing & Capabilities":
- ✅ Location updates (if needed for continuous tracking)
- ✅ Background fetch (optional for periodic updates)
- ✅ Remote notifications (optional for server push)

## Required Capabilities

```xml
<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <!-- Optional -->
    <string>fetch</string>
    <string>remote-notification</string>
</array>

<!-- Background App Refresh -->
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.attendance.beacon.refresh</string>
</array>
```

## Important Notes

1. **Region Monitoring** automatically works in background/terminated state when user grants "Always" location permission
2. **Background App Refresh** must be ON in device Settings
3. App will **NOT** work if user force-quits from app switcher
4. iOS limits to maximum **20 regions** per app
