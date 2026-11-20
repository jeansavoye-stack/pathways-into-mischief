#!/bin/sh
set -eu
PIM_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PIM_OUT="${PIM_BUILD_DIR:-$PIM_ROOT/build}"
PIM_VERSION=$(cat "$PIM_ROOT/VERSION")
PIM_APP="$PIM_OUT/Pathways Into Mischief.app"
mkdir -p "$PIM_APP/Contents/MacOS" "$PIM_APP/Contents/Resources"
clang -arch arm64 -arch x86_64 -mmacosx-version-min=11.5 -fobjc-arc \
  -Wno-deprecated-declarations -Wno-incompatible-pointer-types -O2 \
  -framework Cocoa "$PIM_ROOT/src/main.m" -o "$PIM_APP/Contents/MacOS/PathwaysIntoMischief"
cp "$PIM_ROOT/assets/AppIcon.icns" "$PIM_APP/Contents/Resources/AppIcon.icns"
cp "$PIM_ROOT/assets/Credits.html" "$PIM_APP/Contents/Resources/Credits.html"
cat > "$PIM_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>PathwaysIntoMischief</string>
<key>CFBundleName</key><string>Pathways Into Mischief</string>
<key>CFBundleDisplayName</key><string>Pathways Into Mischief</string>
<key>CFBundleIdentifier</key><string>org.pathwaysintomischief.editor</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.7.0</string>
<key>CFBundleVersion</key><string>7</string>
<key>CFBundleIconFile</key><string>AppIcon.icns</string>
<key>LSMinimumSystemVersion</key><string>11.5</string>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleDevelopmentRegion</key><string>en</string>
<key>NSHumanReadableCopyright</key><string>Copyright © 2026 Pathways Into Mischief contributors. MIT License.</string>
</dict></plist>
PLIST
"$PIM_APP/Contents/MacOS/PathwaysIntoMischief" --self-test
xattr -cr "$PIM_APP"
if [ -n "${PIM_SIGN_IDENTITY:-}" ]; then
  codesign --force --options runtime --timestamp --sign "$PIM_SIGN_IDENTITY" "$PIM_APP"
else
  codesign --force --sign - "$PIM_APP"
fi
codesign --verify --deep --strict "$PIM_APP"
PIM_STAGE="$PIM_OUT/release"
mkdir -p "$PIM_STAGE"
ditto "$PIM_APP" "$PIM_STAGE/Pathways Into Mischief.app"
cp "$PIM_ROOT/README.md" "$PIM_STAGE/README.md"
cp "$PIM_ROOT/LICENSE" "$PIM_STAGE/LICENSE"
cp "$PIM_ROOT/CREDITS.md" "$PIM_STAGE/CREDITS.md"
mkdir -p "$PIM_STAGE/assets"
cp "$PIM_ROOT/assets/AppIcon.png" "$PIM_STAGE/assets/AppIcon.png"
ditto -c -k --sequesterRsrc "$PIM_STAGE" "$PIM_OUT/Pathways-Into-Mischief-$PIM_VERSION-macOS.zip"
shasum -a 256 "$PIM_OUT/Pathways-Into-Mischief-$PIM_VERSION-macOS.zip"
