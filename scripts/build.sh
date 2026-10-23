#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
CORE_VERSION=06a8949e0b3cf60e3a38a374b1426bf40fccb9a0
if [[ ! -f vendor/nestopia/libretro/Makefile ]]; then
  echo '缺少 Nestopia 源码，请按 README 的固定版本步骤准备。' >&2
  exit 1
fi
if [[ -d vendor/nestopia/.git ]] && [[ "$(git -C vendor/nestopia rev-parse HEAD)" != "$CORE_VERSION" ]]; then
  echo '模拟核心版本与锁定版本不一致。' >&2
  exit 1
fi
make -C vendor/nestopia/libretro -j6 platform=osx arch=arm64 CC=clang CXX=clang++ MINVERSION=-mmacosx-version-min=13.0 > artifacts/core-build.log 2>&1
swift build -c release > artifacts/release-build.log 2>&1
APP="$PWD/dist/Paradise Game.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/Cores" "$APP/Contents/Resources/Licenses"
cp .build/release/ParadiseGame "$APP/Contents/MacOS/ParadiseGame"
cp -R Resources/. "$APP/Contents/Resources/"
cp vendor/nestopia/libretro/nestopia_libretro.dylib "$APP/Contents/Resources/Cores/"
cp vendor/nestopia/COPYING "$APP/Contents/Resources/Licenses/Nestopia-GPL-2.0.txt"
cp THIRD_PARTY_NOTICES.md "$APP/Contents/Resources/Licenses/"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.paradise.game</string>
<key>CFBundleName</key><string>Paradise Game</string>
<key>CFBundleDisplayName</key><string>游戏乐园</string>
<key>CFBundleExecutable</key><string>ParadiseGame</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>NSHumanReadableCopyright</key><string>模拟核心使用 Nestopia；原游戏版权归原权利人所有。</string>
</dict></plist>
PLIST
codesign --force --sign - "$APP/Contents/Resources/Cores/nestopia_libretro.dylib"
codesign --force --sign - "$APP"
codesign --verify --deep --strict "$APP"
printf '已构建：%s\n' "$APP"
