#!/usr/bin/env python3
"""
Fix script for 'Multiple commands produce Info.plist' error in Xcode.
This script removes automatic Info.plist generation keys that conflict with manual Info.plist.
"""

import os
import re
import shutil
from pathlib import Path

def fix_project_file():
    """Fix the Xcode project file to prevent duplicate Info.plist generation."""
    
    project_path = Path("/Volumes/DoanBHSST9/FlutterGithubOXII/test_ble_ios/BeaconAttendanceProject/BeaconAttendance/BeaconAttendance.xcodeproj/project.pbxproj")
    
    if not project_path.exists():
        print(f"❌ Project file not found at {project_path}")
        return False
    
    # Create backup
    backup_path = project_path.with_suffix('.pbxproj.backup2')
    shutil.copy2(project_path, backup_path)
    print(f"✅ Created backup at {backup_path}")
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Remove automatic Info.plist generation keys that cause conflicts
    keys_to_remove = [
        r'^\s*"INFOPLIST_KEY_UIApplicationSceneManifest_Generation\[sdk=[^\]]*\]"\s*=\s*YES;\s*$',
        r'^\s*"INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents\[sdk=[^\]]*\]"\s*=\s*YES;\s*$',
        r'^\s*"INFOPLIST_KEY_UILaunchScreen_Generation\[sdk=[^\]]*\]"\s*=\s*YES;\s*$',
        r'^\s*"INFOPLIST_KEY_UIStatusBarStyle\[sdk=[^\]]*\]"\s*=\s*[^;]+;\s*$',
    ]
    
    lines = content.split('\n')
    new_lines = []
    removed_count = 0
    
    for line in lines:
        should_remove = False
        for pattern in keys_to_remove:
            if re.match(pattern, line):
                should_remove = True
                removed_count += 1
                print(f"  Removing: {line.strip()}")
                break
        
        if not should_remove:
            new_lines.append(line)
    
    # Write the updated content
    with open(project_path, 'w') as f:
        f.write('\n'.join(new_lines))
    
    print(f"✅ Removed {removed_count} automatic Info.plist generation keys")
    
    return True

def clean_derived_data():
    """Clean DerivedData to ensure clean build."""
    derived_data_path = Path.home() / "Library/Developer/Xcode/DerivedData"
    
    # Find and remove BeaconAttendance derived data
    for item in derived_data_path.glob("BeaconAttendance-*"):
        if item.is_dir():
            shutil.rmtree(item)
            print(f"✅ Cleaned DerivedData: {item.name}")

def verify_info_plist():
    """Verify that the Info.plist path is correct."""
    project_path = Path("/Volumes/DoanBHSST9/FlutterGithubOXII/test_ble_ios/BeaconAttendanceProject/BeaconAttendance/BeaconAttendance.xcodeproj/project.pbxproj")
    
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Check INFOPLIST_FILE setting
    if 'INFOPLIST_FILE = BeaconAttendanceApp/Resources/Info.plist;' in content:
        print("✅ Info.plist path is correctly set to: BeaconAttendanceApp/Resources/Info.plist")
        
        # Verify the file exists
        info_plist_path = Path("/Volumes/DoanBHSST9/FlutterGithubOXII/test_ble_ios/BeaconAttendanceProject/BeaconAttendance/BeaconAttendanceApp/Resources/Info.plist")
        if info_plist_path.exists():
            print("✅ Info.plist file exists at the specified path")
        else:
            print("⚠️  Warning: Info.plist file not found at the specified path")
            print(f"   Expected at: {info_plist_path}")
    else:
        print("❌ Info.plist path not found in project settings")

def main():
    print("🔧 Fixing 'Multiple commands produce Info.plist' error...")
    print("=" * 60)
    
    # Fix the project file
    if fix_project_file():
        print("\n" + "=" * 60)
        print("📋 Verifying Info.plist configuration...")
        verify_info_plist()
        
        print("\n" + "=" * 60)
        print("🧹 Cleaning DerivedData...")
        clean_derived_data()
        
        print("\n" + "=" * 60)
        print("✅ Fix completed successfully!")
        print("\n📝 Next steps:")
        print("1. Open the project in Xcode")
        print("2. Clean Build Folder (Cmd+Shift+K)")
        print("3. Build the project (Cmd+B)")
        print("\nThe duplicate Info.plist error should now be resolved.")
    else:
        print("❌ Fix failed. Please check the error messages above.")

if __name__ == "__main__":
    main()
