#!/bin/bash
# Validate the actual app's Codable types; the ordinary harnesses use small collaborators.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
derived='build/CustomDebug'
products="$derived/Build/Products/Debug"
macos="$products/Tinycast Custom Dev.app/Contents/MacOS"
mkdir -p build/validation
xcodebuild build -project Tinycast.xcodeproj -scheme Tinycast -configuration Debug \
    -derivedDataPath "$derived" ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO -jobs 2 \
    > build/validation/debug-build.log 2>&1
swiftc -swift-version 6 -parse-as-library -I "$products" \
    Scripts/fixtures/settings-backup-wire-check.swift "$macos/Tinycast Custom Dev.debug.dylib" \
    -Xlinker -rpath -Xlinker "$PWD/$macos" -o build/validation/backup-wire-check
build/validation/backup-wire-check
