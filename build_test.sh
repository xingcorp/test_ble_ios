#!/bin/bash

# Build Test Script for Beacon Attendance
# This script tests compilation without generating Xcode project

echo "🔨 Testing Swift compilation..."
echo "================================"

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Error: Package.swift not found. Please run this script from the project root."
    exit 1
fi

# Clean any existing build artifacts
echo "🧹 Cleaning build artifacts..."
swift package clean 2>/dev/null

# Attempt to build
echo "📦 Building Swift package..."
echo ""

swift build 2>&1 | tee build_output.tmp

# Check build result
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo "✅ Build successful! No compilation errors."
    echo ""
    echo "📝 Next steps:"
    echo "1. Run ./generate_xcode_project.sh to create Xcode project"
    echo "2. Open in Xcode and configure signing"
    echo "3. Build and run on physical device"
    rm -f build_output.tmp
else
    echo ""
    echo "❌ Build failed. See errors above."
    echo ""
    echo "Common fixes:"
    echo "- Check all imports are correct"
    echo "- Verify Swift version (5.7+)"
    echo "- Ensure Xcode Command Line Tools are installed"
    
    # Show unique error messages
    echo ""
    echo "📋 Unique errors found:"
    grep -E "error:|warning:" build_output.tmp | sort -u | head -20
    rm -f build_output.tmp
    exit 1
fi
