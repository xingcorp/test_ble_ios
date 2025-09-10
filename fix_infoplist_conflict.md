# 🔧 Fix "Multiple commands produce Info.plist" Error

## ⚡ Quick Fix (30 seconds)

### Step 1: Open Build Settings
1. Select your target "BeaconAttendance"
2. Go to **Build Settings** tab
3. Make sure "All" and "Combined" are selected

### Step 2: Disable Auto Generation
Search and modify these settings:

| Setting | Value to Set |
|---------|-------------|
| **GENERATE_INFOPLIST_FILE** | **NO** |
| **INFOPLIST_FILE** | `BeaconAttendanceApp/Resources/Info.plist` |
| **INFOPLIST_KEY_**** | Delete all (or leave empty) |

### Step 3: Clean Build Phases
1. Go to **Build Phases** tab
2. Expand **Copy Bundle Resources**
3. Look for any Info.plist file
4. If found, select it and click **-** to remove
   (Info.plist should NOT be in Copy Bundle Resources)

### Step 4: Verify Project Navigator
1. Make sure Info.plist shows correct path
2. Right-click Info.plist → Show File Inspector
3. Target Membership: ✅ BeaconAttendance (but NOT in Copy Bundle Resources)

### Step 5: Clean and Build
```bash
# In Xcode or Terminal
Shift+Cmd+K  # Clean Build Folder
Cmd+B        # Build
```

## 🎯 Why This Happens

Xcode 14+ tries to be "helpful" by:
1. Auto-generating Info.plist when GENERATE_INFOPLIST_FILE = YES
2. You also have manual Info.plist
3. Both get processed → Conflict!

## ✅ Correct Configuration

Your Info.plist should be:
- ✅ Referenced in INFOPLIST_FILE setting
- ✅ Part of target membership
- ❌ NOT in Copy Bundle Resources
- ❌ NOT auto-generated

## 🔍 Verify Success

After fixing, you should see:
- No "Multiple commands" warning
- Build succeeds
- App runs with correct Info.plist settings

## 💡 Pro Tip

If you see this error again after adding files:
- Check Build Phases → Copy Bundle Resources
- Remove any .plist files from there
- Only images, storyboards, and assets should be copied
