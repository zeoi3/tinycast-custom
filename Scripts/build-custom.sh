#!/bin/bash
# Build and package the local arm64 edition; no publishing and no upstream updater.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
identity='Tinycast Custom Local'
derived='build/CustomRelease'
app="$derived/Build/Products/Release/Tinycast Custom.app"
mkdir -p build/validation
xcodebuild -version
if ! security find-identity -p codesigning | /usr/bin/grep -q "\"$identity\""; then
    echo '请先运行 Scripts/setup-custom-signing.sh 创建本机定制签名。' >&2
    exit 1
fi
if ! git diff --quiet || ! git diff --cached --quiet ||
    [ -n "$(git ls-files --others --exclude-standard Tinycast Scripts Tests project.yml)" ]; then
    echo '请先提交代码和工程改动，确保安装包对应明确的源码提交。' >&2
    exit 1
fi
xcodebuild build -project Tinycast.xcodeproj -scheme Tinycast -configuration Release \
    -derivedDataPath "$derived" ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO \
    SWIFT_COMPILATION_MODE=incremental -jobs "${TINYCAST_BUILD_JOBS:-2}" \
    > build/validation/release-build.log 2>&1
codesign --force --sign "$identity" --timestamp=none --options runtime \
    --entitlements Tinycast/Tinycast.entitlements "$app"
codesign --verify --deep --strict --verbose=2 "$app"
version=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$app/Contents/Info.plist")
bundle=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app/Contents/Info.plist")
[ "$bundle" = 'io.github.zeoi3.tinycastcustom' ]
[ "$(lipo -archs "$app/Contents/MacOS/Tinycast Custom")" = 'arm64' ]
package="TinycastCustom-${version}-arm64"
stage=$(mktemp -d "${TMPDIR:-/tmp}/tinycast-custom-package.XXXXXX")
trap 'rm -rf "$stage"' EXIT
ditto "$app" "$stage/Tinycast Custom.app"
ln -s /Applications "$stage/Applications"
cp docs/custom/USAGE.md "$stage/使用说明.md"
cp LICENSE "$stage/LICENSE"
cp NOTICE.md "$stage/NOTICE.md"
{
    echo "Source: $(git rev-parse HEAD)"
    echo "Version: $version"
    echo "Bundle: $bundle"
    echo "Architecture: arm64"
    echo "Signing: $identity (local, not notarized)"
    xcodebuild -version
} > build/BUILD-INFO.txt
cp build/BUILD-INFO.txt "$stage/BUILD-INFO.txt"
# hdiutil atomically replaces only the named build artifact.
hdiutil create -ov -srcfolder "$stage" -volname 'Tinycast Custom' -format UDZO "build/$package.dmg"
ditto -c -k --sequesterRsrc --keepParent "$app" "build/$package.zip"
cp docs/custom/USAGE.md build/使用说明.md

(cd build && shasum -a 256 "$package.dmg" "$package.zip" > SHA256SUMS.txt)
echo "已生成 build/$package.dmg 和 build/$package.zip"
