#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export CLANG_MODULE_CACHE_PATH="$PWD/cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/cache"
swift build -c release --disable-sandbox --cache-path "$PWD/cache" -Xswiftc -module-cache-path -Xswiftc "$PWD/cache"
APP="$PWD/dist/VoltideMac.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --disable-sandbox --show-bin-path)/VoltideMac" "$APP/Contents/MacOS/VoltideMac"
cp LICENSE "$APP/Contents/Resources/LICENSE"
mkdir -p Assets/Voltide.iconset
swiftc -module-cache-path "$PWD/cache" script/draw_icon.swift -o "$PWD/cache/draw_icon"
"$PWD/cache/draw_icon" "$PWD/Assets/Voltide.iconset"
python3 script/package_icon.py "$PWD/Assets/Voltide.iconset" "$APP/Contents/Resources/Voltide.icns"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>VoltideMac</string><key>CFBundleIdentifier</key><string>local.voltide.mac</string><key>CFBundleName</key><string>Voltide for Mac</string><key>CFBundleDisplayName</key><string>Voltide for Mac</string><key>CFBundleIconFile</key><string>Voltide</string><key>CFBundleShortVersionString</key><string>0.1.0</string><key>CFBundleVersion</key><string>1</string><key>CFBundlePackageType</key><string>APPL</string><key>LSMinimumSystemVersion</key><string>13.0</string><key>NSPrincipalClass</key><string>NSApplication</string></dict></plist>
PLIST
case "${1:-run}" in
  --build) ;;
  *) /usr/bin/open -n "$APP" ;;
esac
