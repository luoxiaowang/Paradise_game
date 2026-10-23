# 游戏乐园 · Paradise Game

原生 macOS 小游戏集合，现已包含烟山版 **Tank 1990 (China)** 与 **Super Mario Bros. (World, 1985)**。游戏使用原 ROM 与 Nestopia 模拟核心运行，没有重新编写关卡或规则。大厅和设置为中文，游戏自身保留原版。

## 启动

双击 `dist/Paradise Game.app`。当前构建面向 Apple Silicon，最低声明 macOS 13；实际验证环境另见 `docs/verification.md`。应用使用本地 ad-hoc 签名，未做 Apple Developer ID 签名或公证。

启动后选择游戏卡片的「开始游戏」。

超级玛丽：空格选择单人 / 双人，回车开始；J 跳跃，K 加速 / 火球（获得火焰能力后）。双人按原版规则轮流操作马里奥与路易吉，玩家二使用方向键和逗号 / 句号。

坦克大战原版操作顺序：
1. TANK A～N 菜单：玩家一方向键选择模式，回车确认。
2. 等待原版标题动画结束；空格（Select）切换 `1 PLAYER` / `2 PLAYERS` / `CONSTRUCTION`，回车确认。
3. `STAGE 1` 画面为原版选关界面，可用方向键选择，再按回车开始。

游戏菜单与选关的实际等待均由 ROM 控制，外壳不跳过、不修改。

## 默认按键

| 操作 | 玩家一 | 玩家二 |
|---|---|---|
| 移动 | W / A / S / D | ↑ / ← / ↓ / → |
| A / B | J / K | , / . |
| Start | 回车 | 数字键盘回车 |
| Select | 空格 | 数字键盘 0 |

单 / 双人模式由玩家一在原版菜单选择；玩家二的 Start/Select 保留 FC 映射，不额外改变原游戏支持范围。没有数字键盘时可在设置中改键。

- Esc：应用暂停 / 继续。失焦自动暂停，返回后点击「继续游戏」。
- 工具栏：暂停、重启、静音、设置、全屏、返回大厅。
- 「按键与声音」：点击任意按键再敲新键；Esc 取消录入；冲突时提示且不覆盖旧配置。修改自动保存，恢复默认立即保存。
- 原版 Start 暂停与应用 Esc 暂停是两层不同的暂停；游戏内暂停时仍需原版 Start 恢复。
- 坦克大战双人可同时移动和射击；超级玛丽双人轮流闯关。实际可同时识别的物理按键数受键盘硬件影响。

## 后续增加游戏

直接点击大厅「添加游戏」可导入其他 iNES `.nes` 游戏。文件会复制到 `~/Library/Application Support/ParadiseGame/Games`，清单自动保存，重新打开仍可见。当前运行器面向普通双手柄 FC 游戏；导入不代表所有特殊卡带、光枪、磁碟或外设游戏均已验证。

内置游戏注册在 `Resources/Games/catalog.json`，每项含 `id/title/subtitle/runner/file/sha256`，可选 `preview/players/instructions/actionA/actionB` 定义预览与操作说明。若增加其他平台或原生小游戏，实现 `GameRunner` 并注册 `AppModel.factories`，不必更改 Tank 1990 或 NES 核心。

## 仓库与本地资源

GitHub 仓库包含应用源码、测试、资源清单及构建脚本，不包含游戏 ROM、安装包、构建缓存和第三方源码副本。桌面 DMG 是本机可直接安装版本。克隆后请按下方步骤准备固定版本 Nestopia 源码；游戏通过大厅「添加游戏」导入自行持有的 `.nes` 文件，或将匹配清单 SHA-256 的资源放入 `Resources/Games/` 后构建。原版 ROM 不随源码公开分发。

## 构建

需要 Apple Silicon macOS 和 Swift 5.9+ 命令行工具、clang、make。当前本地目录已包含固定版本核心源码。

```sh
cd /Users/luoxiao/Desktop/code/Paradise_game
./scripts/build.sh
```

重新准备第三方源码（仅缺少 vendor/nestopia 时执行）：

```sh
git clone https://github.com/libretro/nestopia.git vendor/nestopia
git -C vendor/nestopia checkout 06a8949e0b3cf60e3a38a374b1426bf40fccb9a0
```

构建脚本不自动下载游戏，不创建 Git 提交。图标已保存；需要重新生成时运行 `swift scripts/create-icon.swift "$PWD"` 和 `iconutil -c icns artifacts/AppIcon.iconset -o Resources/AppIcon.icns`。

## 验证

```sh
swift run ModelTests
./scripts/test-core.sh
./scripts/test-mario.sh
```

本机仅有 Command Line Tools，缺少 XCTest；模型断言采用独立 Swift 可执行测试程序。核心测试真实运行 ROM，检查异常加载、尺寸、时序、非零音频、单人 / 双人流程与重新打开，输出帧和 PCM 到 `artifacts`。这不等于已逐关对比原始实体卡带。

## 目录

- `Sources/ParadiseKit`：可测试的游戏清单、ROM 校验、输入配置。
- `Sources/ParadiseGame`：大厅、设置、窗口、游戏生命周期、音频与显示。
- `Sources/CoreBridge`：串行 libretro 桥接，像素和音频缓冲。
- `Resources/Games`：独立游戏清单、资源及版本来源记录。
- `scripts`：构建、图标、核心验证。
- `docs`：设计、实施记录和验收边界。

按键配置位于 `~/Library/Application Support/ParadiseGame/keys.json`；音量和静音位于应用 UserDefaults。无联网运行依赖。

第三方来源与许可证见 `THIRD_PARTY_NOTICES.md`。ROM 版本以 `provenance.json` 的 SHA-256 固定，PRG/CHR 匹配 MAME 记录；该记录标记 baddump，因此不声称已证明与所有小霸王卡带完全相同。
