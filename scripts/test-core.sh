#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p artifacts
clang -Wall -Wextra scripts/core-smoke.c Sources/CoreBridge/CoreBridge.c -I Sources/CoreBridge/include -o artifacts/core-smoke
./artifacts/core-smoke "$PWD/vendor/nestopia/libretro/nestopia_libretro.dylib" "$PWD/Resources/Games/tank1990.nes" "$PWD/artifacts"
for name in title one-player-title two-player-title single-player two-player two-player-moving; do
  sips -s format png "artifacts/$name.ppm" --out "artifacts/$name.png" >/dev/null
done

clang -dynamiclib Tests/CoreBridgeTests/failing-core.c -o artifacts/failing-core.dylib
clang Tests/CoreBridgeTests/failed-load.c Sources/CoreBridge/CoreBridge.c -I Sources/CoreBridge/include -o artifacts/test-failed-load
./artifacts/test-failed-load "$PWD/artifacts/failing-core.dylib" "$PWD/Resources/Games/tank1990.nes"
