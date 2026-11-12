# 99 · 时间线

日期取自构建日志与交付文档的文件时间，均为 2026 年。

## 11-02 ~ 11-03：环境与首次出包

| 时间 | 事件 |
| --- | --- |
| 11-02 10:07 | `~/ohos/repo`（repo-py3）就位 |
| 11-03 01:44 | `bin/` 建立（`python -> python3`） |
| 11-03 03:26 | `Dockerfile` 定稿，镜像 `ohos-6.1-rk:jammy-v3` |
| 11-03 05:13 | 补 git-lfs（`lfspull.sh` + `lfs_repos.txt`） |
| 11-03 06:48 | 首次整系统构建成功（RK3588） |
| 11-03 07:03 | `rk3588-images.tar.gz`（791 MB）打包 |
| 11-03 08:06 ~ 08:51 | 并行验证 RV1126B（small/arm）产品，产出 `rv1126b-images.tar.gz` |
| 11-03 09:44 | 修复 `decode_elf.py` shebang 后重打 `uboot.img`（补入 ATF） |
| 11-03 17:44 | 本地烧录包 `ohos-rk3588-images` 成形（README、`flash-rk3588.bat`、`config.cfg`） |

## 11-04：板级设备树对齐

| 时间 | 事件 |
| --- | --- |
| 02:27 | `build-pcie.log` —— PCIe 供电与 reset 修正 |
| 03:22 ~ 05:34 | `build-align-gmac/2/3/4/7.log` —— 与厂商 dts 逐轮对齐（累计 7 轮） |
| 04:56 | `build-shell.log` —— 串口 root shell 开启（`console.cfg`） |
| 05:21 | `build-led.log` —— 状态灯改 `GPIO3_B7` + 打开 heartbeat 配置 |
| 05:48 | `build-hdmi.log` —— HDMI1 / HDMI-IN 检测脚 |
| 06:43 | `build-dsi.log` —— 关闭 DSI0 幻影面板（修 P0 显示宽度） |
| 07:59 | `build-dpi.log` —— `display_manager_config.xml` 的 `<dpi>160</dpi>` |
| 09:59 | `build-cursor.log` —— `MoveSoft` 实验补丁（后被推翻，保留原状） |
| 12:38 | `read-edid.ps1` —— 从 Windows 注册表解 EDID，确认面板原生时序 |
| 14:26 | `KNOWN-ISSUES.md` 定稿（D/N/S/A/B/K/P 系列） |
| 18:16 | `光标问题-交接简报.md`（含误判清单） |

## 11-05：光标根因与 SceneBoard 实验

| 时间 | 事件 |
| --- | --- |
| 02:12 | `libwms-cursor-screen-id.so` 编译完成 —— 定位 `rsId` 漏填根因，推翻 `MoveSoft` 推论 |
| 02:22 | 串口分块传输工具 `serial_file_receiver` 就绪 |
| 上午 | SceneBoard 适配核查：发现 Linux SDK 声明准备被 Windows 判断跳过 |
| 上午 | Linux SDK 准备修正 + Pad SceneBoard 编译/打包/签名通过（HAP 118,993,418 B） |
| 上午 ~ 中午 | 构建启用 SceneBoard 的系统镜像（R1）并只烧 System |
| 中午 | 板上停在 Logo；UART 取证确认 `installed_bundle` 无 `com.ohos.sceneboard` |
| 15:xx | 全刷仍未解决；确认 BMS 走 `USE_PRE_BUNDLE_PROFILE` 且清单缺项 |
| 16:38 | R2 预装清单修复版镜像覆盖 `images/`（备份到 `backups/images-before-sceneboard-r2-20261105-163811/`） |
| 16:39 | `SceneBoard-启动卡住-UART诊断` 记录 |
| 傍晚 | R2 越过 Logo 但黑屏，UART 静默；黑屏根因未定位 |
| 17:19 | 按用户要求停止 SceneBoard，回退经典 WindowManager（源码 + 镜像 + `args.gn`） |
| 当天 | `光标问题-复核记录-20261105.md` 定稿 |

## 11-12：整理归档

| 事件 |
| --- |
| 把上述全过程、脚本、板级 dts、取证文本整理为本仓库（镜像不入库） |
