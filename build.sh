#!/bin/bash

echo "Building Nexus Assistant APK..."

# Clean previous builds
./gradlew clean

# Build debug APK
echo "Building debug APK..."
./gradlew assembleDebug

# Build release APK (unsigned)
echo "Building release APK..."
./gradlew assembleRelease

echo "Build completed!"
echo "Debug APK: app/build/outputs/apk/debug/app-debug.apk"
echo "Release APK: app/build/outputs/apk/release/app-release-unsigned.apk"

# Note: For production, you would need to sign the release APK
echo ""
echo "Note: Release APK is unsigned. For production deployment,"
echo "you need to sign it with your keystore."

