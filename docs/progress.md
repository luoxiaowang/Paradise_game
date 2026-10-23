# Implementation ledger — 2026-10-22-paradise-game
用户已指示直接开始，按原生 inline 方式执行，不再增加批准步骤。
Ruling: 新建目录非 Git 仓库，用户明确指定目录且禁止自动提交；不创建工作树，不运行依赖 commit 的流水账脚本，以本文件追踪。
Pre-flight: Task 1 InputBindings -> Task 3 AppModel；Task 2 C bridge -> NESRunner -> Task 3 AppModel；资源目录 -> 打包脚本；接口统一，无冲突。
Task 1 complete: swift run ModelTests -> 7 model cases passed. Initial XCTest unavailable; independent assertion runner preserves all cases. Tests first observed missing model symbols, then passing implementation. Corrected test fixture choosing already assigned K -> unused L.
Task 2 complete: Nestopia source pinned, ROM CRC matches MAME entry. core-smoke exercised actual ROM and nonzero PCM. Original game has mode menu, title animation and stage confirmation; corrected smoke to cold-load per player scenario because soft reset preserves ROM state.
Task 3 implemented: native SwiftUI/AppKit shell, direct pixels, audio queue, 240 Hz host timer advancing at core fps, settings, import, automatic focus pause. UI verification pending.
Review fixes: key monitor must preserve nil to consume events; confirmation alerts bypass gameplay event handler. User explicitly instructed execution, no Git initialized or committed.
Task 3 complete: native UI launched successfully. Verified conflicting Return while recording does not dismiss settings, custom L persists across app quit/relaunch, restore default J, mute toggle, single and two-player gameplay, pause, confirmation Escape remains paused, full screen roundtrip, return to library.
Task 4 complete: release .app 7 MB arm64, codesign deep/strict valid. Independent review findings fixed. C bridge sanitizer smoke passed; model suite and failed-load cleanup regression passed. Verification boundaries documented.

2026-10-23 final regression: reproduced stale confirmation flag after exit/relaunch in same process. stop/reset explicitly clear it. Rebuilt and repeated complete UI loop: second game Escape shows pause overlay; returned to library. Final DMG rebuilt from this binary.
