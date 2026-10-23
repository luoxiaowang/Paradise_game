#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
clang -Wall -Wextra scripts/mario-smoke.c Sources/CoreBridge/CoreBridge.c -I Sources/CoreBridge/include -o artifacts/mario-smoke
./artifacts/mario-smoke "$PWD/vendor/nestopia/libretro/nestopia_libretro.dylib" "$PWD/Resources/Games/mario.nes" "$PWD/Resources/Games/tank1990.nes" "$PWD/artifacts"
for name in mario-title mario-level mario-jump mario-two-menu mario-luigi mario-luigi-jump; do
 sips -s format png "artifacts/$name.ppm" --out "artifacts/$name.png" >/dev/null
done
