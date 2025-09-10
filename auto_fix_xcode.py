#!/usr/bin/env python3
"""
Auto-fix Xcode project configuration issues
"""

import os
import re
import plistlib
import json
import subprocess
import sys

PROJECT_PATH = "/Volumes/DoanBHSST9/FlutterGithubOXII/test_ble_ios/BeaconAttendanceProject/BeaconAttendance/BeaconAttendance.xcodeproj"
PBXPROJ_PATH = os.path.join(PROJECT_PATH, "project.pbxproj")
INFO_PLIST_PATH = "/Volumes/DoanBHSST9/FlutterGithubOXII/test_ble_ios/BeaconAttendanceProject/BeaconAttendance/BeaconAttendanceApp/Resources/Info.plist"

def backup_file(filepath):
    """Create backup of file before modifying"""
    backup_path = filepath + ".backup"
    if not os.path.exists(backup_path):
        subprocess.run(["cp", filepath, backup_path])
        print(f"✅ Backed up: {os.path.basename(filepath)}")
    return backup_path

def fix_pbxproj():
    """Fix project.pbxproj settings"""
    print("\n🔧 Fixing project.pbxproj...")
    
    if not os.path.exists(PBXPROJ_PATH):
        print(f"❌ Project file not found: {PBXPROJ_PATH}")
        return False
    
    backup_file(PBXPROJ_PATH)
    
    with open(PBXPROJ_PATH, 'r') as f:
        content = f.read()
    
    original_content = content
    
    # Fix 1: Set GENERATE_INFOPLIST_FILE = NO
    print("  - Setting GENERATE_INFOPLIST_FILE = NO")
    content = re.sub(
        r'GENERATE_INFOPLIST_FILE\s*=\s*YES;',
        'GENERATE_INFOPLIST_FILE = NO;',
        content
    )
    
    # Fix 2: Set correct INFOPLIST_FILE path
    print("  - Setting INFOPLIST_FILE path")
    correct_path = 'BeaconAttendanceApp/Resources/Info.plist'
    content = re.sub(
        r'INFOPLIST_FILE\s*=\s*"[^"]*";',
        f'INFOPLIST_FILE = "{correct_path}";',
        content
    )
    
    # Fix 3: Remove INFOPLIST_KEY_ entries
    print("  - Removing INFOPLIST_KEY_ entries")
    content = re.sub(
        r'INFOPLIST_KEY_[A-Za-z_]+\s*=\s*[^;]+;',
        '',
        content
    )
    
    # Fix 4: Clear CODE_SIGN_ENTITLEMENTS if it points to wrong path
    print("  - Fixing CODE_SIGN_ENTITLEMENTS")
    content = re.sub(
        r'CODE_SIGN_ENTITLEMENTS\s*=\s*"[^"]*BeaconAttendance/BeaconAttendance[^"]*";',
        'CODE_SIGN_ENTITLEMENTS = "BeaconAttendance.entitlements";',
        content
    )
    
    # Fix 5: Fix Bundle Identifier
    print("  - Setting Bundle Identifier")
    content = re.sub(
        r'PRODUCT_BUNDLE_IDENTIFIER\s*=\s*"[^"]*";',
        'PRODUCT_BUNDLE_IDENTIFIER = "com.oxii.BeaconAttendance";',
        content
    )
    
    # Fix 6: Set Development Team (empty for now, user needs to set)
    print("  - Clearing DEVELOPMENT_TEAM for manual setting")
    content = re.sub(
        r'DEVELOPMENT_TEAM\s*=\s*[^;]+;',
        'DEVELOPMENT_TEAM = "";',
        content
    )
    
    if content != original_content:
        with open(PBXPROJ_PATH, 'w') as f:
            f.write(content)
        print("✅ Fixed project.pbxproj")
        return True
    else:
        print("ℹ️  No changes needed in project.pbxproj")
        return False

def fix_info_plist():
    """Ensure Info.plist has required keys"""
    print("\n🔧 Checking Info.plist...")
    
    if not os.path.exists(INFO_PLIST_PATH):
        print(f"❌ Info.plist not found at: {INFO_PLIST_PATH}")
        return False
    
    try:
        with open(INFO_PLIST_PATH, 'rb') as f:
            plist = plistlib.load(f)
        
        # Required keys for beacon app
        required_keys = {
            'NSLocationAlwaysAndWhenInUseUsageDescription': 'Beacon Attendance needs location access to detect when you enter or leave work sites.',
            'NSLocationWhenInUseUsageDescription': 'Beacon Attendance needs location access to detect nearby beacons.',
            'NSLocationAlwaysUsageDescription': 'Beacon Attendance needs background location access for automatic attendance tracking.',
            'NSBluetoothAlwaysUsageDescription': 'Beacon Attendance uses Bluetooth to detect proximity beacons.',
            'UIBackgroundModes': ['bluetooth-central', 'location', 'fetch', 'processing'],
            'CFBundleIdentifier': 'com.oxii.BeaconAttendance',
            'CFBundleDisplayName': 'Beacon Attendance',
            'LSRequiresIPhoneOS': True
        }
        
        modified = False
        for key, value in required_keys.items():
            if key not in plist or plist[key] != value:
                plist[key] = value
                modified = True
                print(f"  - Added/Updated: {key}")
        
        if modified:
            backup_file(INFO_PLIST_PATH)
            with open(INFO_PLIST_PATH, 'wb') as f:
                plistlib.dump(plist, f)
            print("✅ Fixed Info.plist")
            return True
        else:
            print("✅ Info.plist is correct")
            return False
            
    except Exception as e:
        print(f"❌ Error processing Info.plist: {e}")
        return False

def remove_info_plist_from_copy_resources():
    """Remove Info.plist from Copy Bundle Resources phase"""
    print("\n🔧 Checking Copy Bundle Resources...")
    
    with open(PBXPROJ_PATH, 'r') as f:
        content = f.read()
    
    # Find and remove Info.plist from resources build phase
    # This regex finds Info.plist entries in PBXResourcesBuildPhase
    pattern = r'([A-F0-9]{24}\s*/\*\s*Info\.plist\s*\*/\s*in\s*Resources\s*\*/,?\s*)'
    matches = re.findall(pattern, content)
    
    if matches:
        print(f"  - Found {len(matches)} Info.plist entries in Copy Bundle Resources")
        for match in matches:
            content = content.replace(match, '')
        
        with open(PBXPROJ_PATH, 'w') as f:
            f.write(content)
        print("✅ Removed Info.plist from Copy Bundle Resources")
        return True
    else:
        print("✅ Info.plist not in Copy Bundle Resources (correct)")
        return False

def clean_build():
    """Clean build folder"""
    print("\n🧹 Cleaning build folder...")
    
    derived_data = os.path.expanduser("~/Library/Developer/Xcode/DerivedData")
    beacon_dirs = []
    
    for dir_name in os.listdir(derived_data):
        if dir_name.startswith("BeaconAttendance-"):
            full_path = os.path.join(derived_data, dir_name)
            beacon_dirs.append(full_path)
    
    for dir_path in beacon_dirs:
        try:
            subprocess.run(["rm", "-rf", dir_path], check=True)
            print(f"  - Removed: {os.path.basename(dir_path)}")
        except:
            pass
    
    if beacon_dirs:
        print("✅ Cleaned DerivedData")
    else:
        print("ℹ️  No DerivedData to clean")

def main():
    print("🚀 Auto-fixing Xcode Project Issues")
    print("=" * 50)
    
    # Check if project exists
    if not os.path.exists(PROJECT_PATH):
        print(f"❌ Project not found at: {PROJECT_PATH}")
        sys.exit(1)
    
    changes_made = False
    
    # Fix project settings
    if fix_pbxproj():
        changes_made = True
    
    # Fix Info.plist
    if fix_info_plist():
        changes_made = True
    
    # Remove Info.plist from resources
    if remove_info_plist_from_copy_resources():
        changes_made = True
    
    # Clean build
    clean_build()
    
    print("\n" + "=" * 50)
    if changes_made:
        print("✅ Fixes applied successfully!")
        print("\n📋 Next steps:")
        print("1. Open Xcode project")
        print("2. Select Team in Signing & Capabilities")
        print("3. Click 'Try Again' if there are signing errors")
        print("4. Build (Cmd+B)")
    else:
        print("✅ No fixes needed - project looks good!")
    
    print("\n💡 If issues persist:")
    print("- Check Signing & Capabilities tab")
    print("- Ensure device is connected")
    print("- Try switching to Personal Team temporarily")

if __name__ == "__main__":
    main()
