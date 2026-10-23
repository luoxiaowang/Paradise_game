# 第三方组件与游戏资源

## Nestopia / libretro
- 源码：https://github.com/libretro/nestopia
- 固定提交：06a8949e0b3cf60e3a38a374b1426bf40fccb9a0
- GPL-2.0，完整许可证随应用提供，源码保留在 vendor/nestopia。
- 核心未修改；前端使用其 libretro C 接口。项目自有代码按 GPL-2.0 提供，游戏 ROM 不属于该开源许可证。

## Tank 1990
- 游戏为烟山版 Tank 1990 (China)，源自 Battle City；原游戏及改版内容版权归相应权利人。
- 本地开发资源下载来源与哈希详见 Resources/Games/provenance.json。
- PRG/CHR CRC32 与 MAME 官方 tank1990 条目一致，但该条目标记 baddump，不代表已证实完美卡带转储。
- 未获得 ROM 再分发授权证明；此本地交付不表示具备公开分发或商店上架许可。公开发布时应移除 ROM，使用本地导入功能，或另行取得授权。
- 应用运行无需访问网络、账号或远程服务。

## Super Mario Bros.
- Nintendo 1985 年 FC 原版；标题、关卡、画面和音频均由原程序运行，未修改游戏数据。
- 下载来源、SHA-256 与对照记录见 Resources/Games/mario-provenance.json。
- PRG CRC32 5cf548d3、CHR CRC32 867b51ad，与 MAME 官方 nes.xml 的 smb1 (World) 条目一致。
- 原游戏版权归 Nintendo；ROM 不属于本项目 GPL 许可证，未取得公开再分发授权证明。
