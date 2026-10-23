# Paradise Game Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 交付可启动的 macOS 游戏集合，首期运行 Tank 1990，支持声音、单人双人和改键。
**Architecture:** Swift/AppKit + SwiftUI 原生外壳，GameRunner 生命周期隔离模拟实现，C 桥接 libretro Nestopia，资源清单独立注册。
**Tech Stack:** Swift 6.1（Swift 5 语言模式）、AppKit、SwiftUI、AVAudioEngine、C、Nestopia。
**Spec:** ../specs/2026-10-22-paradise-game-design.md

## Global Constraints
- 项目路径 /Users/luoxiao/Desktop/code/Paradise_game；不自动 Git commit。
- 中文外壳，ROM 画面和声音保持原样。
- Apple Silicon macOS 首发，后续游戏通过清单和运行器扩展。
- 不把编译或核心测试通过称为完全还原；记录未覆盖的原版对照范围。

## Review Focus
- 无效或截断 ROM 必须安全拒绝（任务 1、2）。
- 同时按键与失焦不得卡键（任务 1、3）。
- 暂停、退出和重新进入不得残留声音（任务 2、3）。
- 重复启动、关闭、缺少核心时不得崩溃（任务 2、3）。
- 改键冲突、损坏配置及重启持久化（任务 1、3）。

### Task 1: 游戏目录与输入配置
Files: Package.swift, Sources/ParadiseKit/{GameCatalog,InputBindings,ROMValidator}.swift, Tests/ParadiseKitTests/ParadiseKitTests.swift
Interfaces: GameDescriptor; GameCatalog.load(url:); InputBindings.assign(player:button:key:), masks(pressed:), save(to:), load(from:); ROMValidator.validate(_:).
- [x] 先编写并运行 ROM 截断、清单重复 ID、按键冲突/同时输入/释放/配置恢复测试，确认缺失功能导致失败。
- [x] 实现可测试模型、严格 ROM 大小校验、不可重复按键映射与持久化。
- [x] swift test 全部通过。

### Task 2: NES 运行器与资源
Files: Sources/CoreBridge/{CoreBridge.c,include/CoreBridge.h}, Sources/ParadiseGame/{NESRunner,AudioOutput}.swift, scripts/core-smoke.c, Resources/Games/catalog.json, vendor/nestopia
Interfaces: pg_open(core,rom), pg_run(), pg_set_input(player,mask), pg_video(), pg_read_audio(), pg_reset(), pg_close(); GameRunner 协议。
- [x] 固定模拟核心版本和游戏来源/哈希，审阅构建入口后编译。
- [x] 先用 C 冒烟程序定义加载失败、重复关闭、逐帧视频/音频和双玩家输入断言，运行确认桥接尚未实现。
- [x] 实现 libretro 回调、像素转换、音频缓冲和错误返回；模拟核心所有调用在主线程串行。
- [x] 运行真实 ROM 冒烟，保存标题、单人、双人帧及音频样本。

### Task 3: 原生游戏大厅与设置
Files: Sources/ParadiseGame/{main,AppModel,LibraryView,GameView,SettingsView,PixelView}.swift
Interfaces: AppModel 驱动 GameRunner；SwiftUI 视图只处理用户操作和状态；InputBindings 转换原生 keyCode。
- [x] 按已定义验收场景搭建大厅、启动/暂停/重置/返回、设置和本地导入。
- [x] 以单调时钟驱动原帧率，显示最近一帧，限制追帧，音频有界缓冲。
- [x] 游戏失焦自动暂停并清空输入；设置录键支持取消、冲突提示和保存。
- [x] 构建并启动实机 UI，核验单人双人、改键、全屏和往返；记录未能自动核验项。

### Task 4: 打包、独立审阅与交付
Files: scripts/build.sh, README.md, docs/verification.md, THIRD_PARTY_NOTICES.md
- [x] 创建 .app 包、嵌入核心与资源、添加图标与本地 ad-hoc 签名。
- [x] 运行全部模型测试和核心冒烟，验证签名与依赖路径。
- [x] 使用 executing-plans 要求的一次独立审阅，修复实质问题并重跑相关检查。
- [x] 交付 .app、源码、构建方式及准确验证边界，不提交 Git。
