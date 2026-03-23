#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${1:-$ROOT_DIR/release}"
BUILD_DIR="$OUT_DIR/build"
PKG_DIR="$OUT_DIR/abigail-flower-mac-package"
APP_NAME="阿比盖尔之花"
APP_BUNDLE="$PKG_DIR/$APP_NAME.app"
ZIP_PATH="$OUT_DIR/abigail-flower-mac-package.zip"

rm -rf "$BUILD_DIR" "$PKG_DIR" "$ZIP_PATH"
mkdir -p "$OUT_DIR"

BUILT_APP="$($ROOT_DIR/scripts/build_app.sh "$BUILD_DIR")"
mkdir -p "$PKG_DIR"
cp -R "$BUILT_APP" "$APP_BUNDLE"

cat > "$PKG_DIR/INSTALL.command" <<INSTALL
#!/bin/bash
set -euo pipefail
APP_DIR="\$HOME/Applications"
APP_BUNDLE="\$APP_DIR/$APP_NAME.app"
SOURCE_DIR="\$(cd "\$(dirname "\$0")" && pwd)/$APP_NAME.app"
PLIST_DEST="\$HOME/Library/LaunchAgents/com.abigailflower.card.plist"
mkdir -p "\$APP_DIR" "\$HOME/Library/LaunchAgents"
pkill -f '/$APP_NAME.app/Contents/MacOS/AbigailFlowerCard' >/dev/null 2>&1 || true
rm -rf "\$APP_BUNDLE"
cp -R "\$SOURCE_DIR" "\$APP_BUNDLE"
cat > "\$PLIST_DEST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.abigailflower.card</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/open</string>
    <string>-gj</string>
    <string>\$APP_BUNDLE</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
</dict>
</plist>
PLIST
launchctl bootout "gui/\$(id -u)" "\$PLIST_DEST" >/dev/null 2>&1 || true
launchctl bootstrap "gui/\$(id -u)" "\$PLIST_DEST"
open -gj "\$APP_BUNDLE"
echo "已安装到 \$APP_BUNDLE"
INSTALL
chmod +x "$PKG_DIR/INSTALL.command"

cat > "$PKG_DIR/UNINSTALL.command" <<'UNINSTALL'
#!/bin/bash
set -euo pipefail
APP_BUNDLE="$HOME/Applications/阿比盖尔之花.app"
PLIST_DEST="$HOME/Library/LaunchAgents/com.abigailflower.card.plist"
SUPPORT_DIR="$HOME/Library/Application Support/AbigailFlowerCard"
pkill -f '/阿比盖尔之花.app/Contents/MacOS/AbigailFlowerCard' >/dev/null 2>&1 || true
launchctl bootout "gui/$(id -u)" "$PLIST_DEST" >/dev/null 2>&1 || true
rm -f "$PLIST_DEST"
rm -rf "$APP_BUNDLE"
rm -rf "$SUPPORT_DIR"
echo "阿比盖尔之花已卸载。"
UNINSTALL
chmod +x "$PKG_DIR/UNINSTALL.command"

cat > "$PKG_DIR/README.md" <<'README'
# 阿比盖尔之花

## 安装
1. 双击 `INSTALL.command`
2. 如果 macOS 提示安全限制，右键 `INSTALL.command` 选择“打开”
3. 安装完成后，卡片会出现在桌面上

## 安装后会发生什么
- app 会被安装到 `~/Applications/阿比盖尔之花.app`
- 自动启动配置会写到 `~/Library/LaunchAgents/com.abigailflower.card.plist`
- 默认配置和文案库会放到 `~/Library/Application Support/AbigailFlowerCard`

## 卸载
1. 双击 `UNINSTALL.command`
2. 卸载脚本会删除 app、自动启动项和本地配置
README

( cd "$OUT_DIR" && /usr/bin/zip -qry "$ZIP_PATH" "$(basename "$PKG_DIR")" )
printf '%s\n' "$ZIP_PATH"
