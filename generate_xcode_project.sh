#!/bin/bash

# Generate Xcode Project Script for Beacon Attendance
# Run this script to generate the Xcode project file

echo "🚀 Generating Xcode project for Beacon Attendance..."

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Package.swift not found. Please run this script from the project root."
    exit 1
fi

# Clean any existing build artifacts
echo "🧹 Cleaning build artifacts..."
rm -rf .build
rm -rf .swiftpm

# Generate Xcode project using Swift Package Manager
echo "📦 Generating Xcode project from Package.swift..."
swift package generate-xcodeproj

# Check if generation was successful
if [ $? -eq 0 ]; then
    echo "✅ Xcode project generated successfully!"
    echo "📂 Project file: BeaconAttendance.xcodeproj"
    echo ""
    echo "📝 Next steps:"
    echo "1. Open BeaconAttendance.xcodeproj in Xcode"
    echo "2. Select a development team in project settings"
    echo "3. Set the deployment target to iOS 14.0+"
    echo "4. Build and run on a physical device (iBeacon doesn't work on simulator)"
    echo ""
    echo "⚠️  Important:"
    echo "- Test on a real device (iBeacon requires physical hardware)"
    echo "- Grant 'Always' location permission when prompted"
    echo "- Enable Background App Refresh in Settings"
    echo "- Have a beacon with UUID: FDA50693-0000-0000-0000-290995101092"
else
    echo "❌ Failed to generate Xcode project"
    echo "Please ensure you have Xcode and Swift tools installed"
    exit 1
fi
