# 许可证、第三方来源与修改说明

本仓库原创文档、脚本和原创修改采用 [Apache License 2.0](LICENSE)，版权归各贡献者。
第三方文件遵循文件头或原项目许可；根许可证不替换这些许可，也不授予未收录产物的再分发权。

| 本仓库材料 | 来源与版权 | 许可与本地修改 |
| --- | --- | --- |
| `scripts/board/input_window_monitor.cpp[.orig]`、`input_window_monitor_test.cpp`、相关补丁与证据片段 | OpenHarmony `foundation/window/window_manager`；Huawei Device Co., Ltd. 2021–2022 / 2022；取证 HEAD `ac4fbeff04b9560fb004f8ecb834aeccfc66bffd` | Apache-2.0；保留原版权头。修改为填充 RS/物理屏幕 ID、窗口 displayId、结构体初始化和无效屏幕检查，并调整测试；`.orig` 为改前副本 |
| `scripts/sceneboard/SceneBoard-hvigorfile.ts[.orig]`、`update-sdk-interface.js[.orig]`、`evidence/SceneBoard-build.sh`、相关补丁与证据片段 | OpenHarmony `applications/standard/window_scene_board`；Huawei Device Co., Ltd. 2023 / 2024–2025；见文件头及 [SDK 准备记录](evidence/sceneboard-sdk-preparation-review.txt) | Apache-2.0；修改为 Linux 入口执行、独立 Node 参数、SDK 路径检查、TypeScript 配置解析及错误传播；`.orig` 与 `SceneBoard-build.sh` 为历史副本 |
| `board-dts/rk3588-evb7-v11-standard.dts` | Rockchip Electronics Co., Ltd. 2023；由 RK3588 EVB7 板级 DTS 调整，参照 [AndroidOL/Archive-DC-A588](https://github.com/AndroidOL/Archive-DC-A588) 厂商固件的引脚与状态 | 保留 `(GPL-2.0+ OR MIT)` 声明，本仓库选择 [MIT](LICENSES/MIT.txt) 分支再分发。修改涉及 PCIe 供电/复位、GMAC、UART、音频、显示与外设开关，详见 [板级说明](docs/04-board-dts.md) |
| `evidence/` 中其他上游源码节选与 diff | OpenHarmony 对应组件及 Rockchip 产品配置；原路径与 diff 记录保留在文件内 | 保留原材料的许可和版权；这些片段不构成完整上游源码发行版。已知归档缺口见 [源码基线](docs/11-reproducibility.md) |

上游入口为 [caesar-wang/manifest](https://gitcode.com/caesar-wang/manifest) 的 `OpenHarmony-6.1-RK-LTS` 分支，
项目间关系由其 manifest 决定。历史实际构建机 remote 为另一镜像，且没有完整冻结 manifest；
本表不把当前默认分支当成历史版本，也不声称已完成历史各组件 NOTICE 的逐提交比对。
现有文件版权头已保留并在 [NOTICE](NOTICE) 汇总；后续增加或替换源码时，应从实际固定版本同步其适用的 LICENSE/NOTICE。

镜像、SDK、签名密钥、固件二进制、RKDevTool 和 DriverAssistant 安装包未随本仓库分发。
文档中的名称、校验值和使用方法不代表这些产物采用本仓库许可证；请从其上游或板卡厂商获取，遵循各自产物条款。
本项目是社区适配归档，不代表 OpenHarmony、Huawei、Rockchip 或板卡厂商的官方认证。
