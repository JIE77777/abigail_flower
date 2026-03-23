#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_SOURCE_DIR="$ROOT_DIR/App"
OUTPUT_ROOT="${1:-$ROOT_DIR/build}"
APP_NAME="阿比盖尔之花"
EXEC_NAME="AbigailFlowerCard"
BUNDLE_ID="com.abigailflower.card"
APP_BUNDLE="$OUTPUT_ROOT/$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
DEFAULTS_DIR="$RESOURCES_DIR/Defaults"
ICON_SOURCE="$APP_SOURCE_DIR/Resources/AppIcon/AbigailFlower.icns"
PNG_SOURCE="$APP_SOURCE_DIR/Resources/AppIcon/AbigailFlower.png"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "需要在 macOS 上安装 Xcode Command Line Tools 后再运行。" >&2
  exit 1
fi

SWIFTC="$(xcrun --sdk macosx --find swiftc 2>/dev/null || true)"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
if [[ -z "$SWIFTC" || -z "$SDK_PATH" ]]; then
  echo "没有找到 macOS Swift 工具链，请先安装 Xcode 或 Command Line Tools。" >&2
  exit 1
fi

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp -R "$APP_SOURCE_DIR/Resources/Defaults" "$DEFAULTS_DIR"
cp "$ICON_SOURCE" "$RESOURCES_DIR/AbigailFlower.icns"
cp "$PNG_SOURCE" "$RESOURCES_DIR/AbigailFlower.png"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleExecutable</key>
  <string>$EXEC_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AbigailFlower</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

SWIFT_SOURCES=()
while IFS= read -r source_file; do
  SWIFT_SOURCES+=("$source_file")
done < <(find "$APP_SOURCE_DIR/Sources/AbigailFlowerCard" -name '*.swift' | sort)
if [[ ${#SWIFT_SOURCES[@]} -eq 0 ]]; then
  echo "没有找到 Swift 源码。" >&2
  exit 1
fi

"$SWIFTC" \
  -sdk "$SDK_PATH" \
  -O \
  -module-name AbigailFlowerCard \
  -framework SwiftUI \
  -framework AppKit \
  "${SWIFT_SOURCES[@]}" \
  -o "$MACOS_DIR/$EXEC_NAME"

chmod +x "$MACOS_DIR/$EXEC_NAME"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

if command -v plutil >/dev/null 2>&1; then
  plutil -lint "$CONTENTS_DIR/Info.plist" >/dev/null
fi

printf '%s\n' "$APP_BUNDLE"
