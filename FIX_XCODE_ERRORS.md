# 🔧 Fix Xcode Project Configuration

## ✅ Quick Fix for Entitlements Error

### 1. Fix Entitlements Path
1. Open your project in Xcode
2. Select the **BeaconAttendance** target
3. Go to **Build Settings** tab
4. Search for "entitlements"
5. Find **CODE_SIGN_ENTITLEMENTS**
6. Change the value to: `BeaconAttendance.entitlements`
   (Not the nested path with multiple BeaconAttendance folders)

### 2. Fix Info.plist Path
1. Still in **Build Settings**
2. Search for "info.plist"
3. Find **INFOPLIST_FILE**
4. Change the value to: `BeaconAttendanceApp/Resources/Info.plist`

### 3. Clean Folder Structure (Optional)
It looks like you have nested BeaconAttendance folders. The correct structure should be:
```
BeaconAttendanceProject/
├── BeaconAttendance/           # Main project folder
│   ├── BeaconAttendance.xcodeproj
│   ├── BeaconAttendance.entitlements  # ✅ Created now
│   ├── BeaconAttendanceApp/    # Your app files
│   │   ├── Sources/
│   │   │   ├── AppDelegate.swift
│   │   │   ├── SceneDelegate.swift
│   │   │   └── AttendanceViewController.swift
│   │   └── Resources/
│   │       ├── Info.plist      # ✅ Already exists
│   │       ├── LaunchScreen.storyboard
│   │       └── Assets.xcassets/
│   └── (Other folders like Tests)
```

## 🎯 Verify in Xcode

### In Project Navigator:
- ✅ BeaconAttendance.entitlements should appear
- ✅ Info.plist should be under BeaconAttendanceApp/Resources

### In Target Settings > General:
- **Bundle Identifier**: com.oxii.BeaconAttendance (or your custom)
- **Deployment Info**: iOS 14.0+
- **App Icons Source**: Assets (should auto-detect)

### In Target Settings > Signing & Capabilities:
- **Team**: Your development team
- **Signing Certificate**: Automatic
- **Provisioning Profile**: Automatic
- **Capabilities**: Background Modes should show

## 🚀 After Fixing:

1. **Clean Build Folder**: Shift+Cmd+K
2. **Build**: Cmd+B
3. Should compile without entitlements error!

## 💡 Pro Tips:

### If you still see path errors:
- Right-click the file in Xcode navigator
- Select "Show in Finder"
- Note the actual path
- Update Build Settings accordingly

### If capabilities don't show:
- Click **+ Capability** button
- Add **Background Modes**
- Check these options:
  - ✅ Uses Bluetooth LE accessories
  - ✅ Location updates
  - ✅ Background fetch
  - ✅ Background processing

### For Package Dependencies:
Make sure you've added the local packages:
1. File → Add Package Dependencies
2. Add Local → Select the `test_ble_ios` folder
3. Add both:
   - BeaconAttendanceCore
   - BeaconAttendanceFeatures

## ✨ Success Checklist:
- [ ] No entitlements error
- [ ] No Info.plist error
- [ ] Project builds successfully
- [ ] Can run on simulator (UI only)
- [ ] Can deploy to device (full features)
