#!/bin/bash

echo "🔧 Registering iOS Device with Xcode..."
echo ""
echo "Method 1: Via Xcode UI"
echo "========================"
echo "1. Open Xcode"
echo "2. Window → Devices and Simulators (Shift+Cmd+2)"
echo "3. Select your iPhone in left panel"
echo "4. Click 'Use for Development'"
echo "5. Enter Apple ID password if prompted"
echo ""

echo "Method 2: Via Command Line"
echo "========================"
# Get device info
echo "Getting connected devices..."
xcrun devicectl list devices --json-output /tmp/devices.json 2>/dev/null

if [ -f /tmp/devices.json ]; then
    echo "Found devices info"
    cat /tmp/devices.json | python3 -m json.tool | grep -E '"name"|"identifier"' | head -10
fi

echo ""
echo "Method 3: Manual Registration"
echo "========================"
echo "1. Go to: https://developer.apple.com/account/resources/devices/list"
echo "2. Click '+' to add device"
echo "3. Device Name: DoanBH's iPhone"
echo "4. Device ID (UDID): a6635bbceb27f186c39166b75edf3b876abd3a7a"
echo "5. Continue → Register"
echo ""

echo "Method 4: Use Existing Project"
echo "========================"
echo "Open a working Flutter project and run it once:"
echo "open /Volumes/DoanBHSST9/FlutterOXI/kteam-app/plugins/flutter_core_app/smooth/example/ios/Runner.xcodeproj"
echo ""
echo "This will auto-register your device for the team"

echo ""
echo "After Registration:"
echo "==================="
echo "1. Go back to BeaconAttendance project"
echo "2. Clean Build Folder (Shift+Cmd+K)"
echo "3. Click 'Try Again' in Signing section"
echo "4. Build and Run"
