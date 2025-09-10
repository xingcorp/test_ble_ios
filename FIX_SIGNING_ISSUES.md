# 🔧 Fix Xcode Signing & Capabilities Issues

## ⚡ Quick Fix (5 phút)

### Step 1: Clear Manual Entitlements
1. Select project → Target "BeaconAttendance"
2. **Build Settings** tab
3. Search: "entitlements"
4. **CODE_SIGN_ENTITLEMENTS** → **Delete value completely** (leave blank)
5. Delete the manual .entitlements file from project

### Step 2: Reset Signing
1. **Signing & Capabilities** tab
2. **Uncheck** "Automatically manage signing"
3. **Check** it again
4. Team: SHARITEK VIETNAM COMPANY LIMITED

### Step 3: Add Capabilities Properly via UI
1. Click **"+ Capability"** button
2. Add **Background Modes**:
   - Double-click to add
   - In the new panel, check:
     - ✅ Location updates
     - ✅ Uses Bluetooth LE accessories
     - ✅ Background fetch
     - ✅ Background processing
     - ✅ Remote notifications (if needed)

### Step 4: Fix Location Permission
Location "Always" is **NOT an entitlement** - it's an Info.plist configuration:

1. Verify Info.plist has these keys:
```xml
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Need location for beacon detection</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Need location for beacon detection</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Need background location for attendance</string>
```

2. **Important**: Do NOT add location to entitlements manually

### Step 5: Register Device
1. Click **"Try Again"** button in the error panel
2. Xcode will automatically:
   - Register your device with Apple
   - Generate new provisioning profile
   - Include all capabilities

### Step 6: Clean & Build
1. **Shift+Cmd+K** (Clean Build Folder)
2. **Cmd+B** (Build)

## 🎯 Why This Works:

### ✅ Correct Approach:
- Xcode manages entitlements automatically
- Capabilities added via UI are properly configured
- Provisioning profiles auto-generated with correct permissions
- Device registration handled automatically

### ❌ What Was Wrong:
- Manual entitlements file conflicts with automatic signing
- Location.always is NOT an entitlement (common misconception)
- Mixed manual and automatic configuration

## 📱 Alternative: Personal Team (If Company Team Fails)

If SHARITEK team still has issues:

1. **Signing & Capabilities**
2. Team: Change to **"DoanBH (Personal Team)"**
3. Bundle ID: Change to **"com.doanbh.BeaconAttendance"**
4. Add capabilities as above
5. Build & Run

**Note**: Personal team apps expire after 7 days

## 🔍 Verify Success:

After following steps, you should see:
- ✅ No red errors in Signing section
- ✅ "Provisioning Profile: Xcode Managed Profile"
- ✅ "Signing Certificate: Apple Development"
- ✅ Background Modes capability shows in list
- ✅ Build succeeds

## 💡 Pro Tips:

1. **Always use Xcode UI for capabilities** when using automatic signing
2. **Never mix** manual entitlements with automatic signing
3. **Location permissions** go in Info.plist, not entitlements
4. **"Try Again"** button usually fixes device registration

## 🚨 If Still Failing:

Check these:
1. Internet connection (for device registration)
2. Apple Developer account is active
3. Team has necessary app capabilities enabled
4. Xcode is signed in (Preferences → Accounts)

## 📝 Common Misconceptions:

| Wrong ❌ | Right ✅ |
|---------|---------|
| Location.always in entitlements | Location.always in Info.plist only |
| Manual entitlements with auto signing | Use Xcode UI for capabilities |
| Edit provisioning profiles manually | Let Xcode manage everything |
| Register device on developer portal | Click "Try Again" in Xcode |
