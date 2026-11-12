# 定昌 DC-A588 (RK3588) OpenHarmony 6.1-RK-LTS 适配工程

本仓库整理 **DC-A588-V04 载板 + DC-CM3588 核心板（RK3588）** 移植 OpenHarmony 6.1-RK-LTS 的完整过程：
构建环境搭建、源码同步、板级设备树适配、系统构建、镜像烧录、板端取证与调试、已知问题，以及两条后续专项
（SceneBoard 新桌面架构迁移、鼠标光标问题）的全部记录与脚本。

一手材料来自 2026-10 ~ 2026-11 的实际工作环境：
构建机 `<BUILD_HOST>:<SSH_PORT>`（Ubuntu 24.04，96 核）中的 `~/ohos`，以及本机交付目录
`ohos-rk3588-images`（镜像、烧录工具、取证文本）。仓库只保存**文本、脚本、设备树与校验清单**，
2 GB 级别的镜像文件不入库，见 [docs/05-flashing.md](docs/05-flashing.md)。

## 当前状态

| 项 | 状态 |
| --- | --- |
| 系统启动 | 可启动到 `bootevent.boot.completed`，经典 WindowManager 进入桌面 |
| 显示 | HDMI OUT0 正常；HDMI OUT1 已绑定并出图；DSI0 因无面板关闭；DP0/DP1（与 HDMI 复用连接器）关闭 |
| 网络 | eth0（GMAC0 + RTL8211F）通路可用，实测只协商到 100 Mbps（待查线材/交换机）；eth1（RTL8111）需插线验证 |
| 存储 | eMMC 正常；TF 卡、SATA 盘未插卡/盘验证 |
| 音频 | ES8388 声卡注册成功，未做实际播放验证 |
| 蓝牙 | 驱动层就绪（ttyS8），协议栈未验证 |
| USB | 设备/主机模式未完整验证；`usb_host` 服务存在 SIGSEGV 重启循环（厂商 HDI 缺陷） |
| 摄像头 / CAN / RTC / LVDS | 未适配，缺厂商原理图或硬件 |
| 鼠标光标 | 已定位真实根因（WindowManager 漏填 `rsId`），修正库已编译但**未上板验证** |
| SceneBoard | 已完成编译/打包/预装修复，R2 能跑起桌面进程，但随后黑屏，**按用户要求停止该方向并回退经典版本** |

完整清单见 [docs/07-known-issues.md](docs/07-known-issues.md)，原始版本见
[docs/original/KNOWN-ISSUES.md](docs/original/KNOWN-ISSUES.md)。

## 目录

```
.
├── docs/
│   ├── 01-hardware.md            板卡硬件、丝印、引脚、接口实测
│   ├── 02-build-environment.md   构建主机与 Docker 容器
│   ├── 03-source-and-build.md    repo 同步、prebuilts、构建命令与产物
│   ├── 04-board-dts.md           板级设备树适配（逐项覆写与理由）
│   ├── 05-flashing.md            RKDevTool 烧录、分区表、ATF 打包坑
│   ├── 06-onboard-debug.md       串口 / hdc / hilog / 文件传输取证
│   ├── 07-known-issues.md        已知问题总表
│   ├── 08-sceneboard-experiment.md  SceneBoard 迁移全过程
│   ├── 09-cursor-investigation.md   光标问题调查与结论
│   ├── 10-pitfalls.md            反复踩的坑（工具链/构建/设备树）
│   ├── 99-timeline.md            时间线
│   └── original/                 一手交付文档（原文归档，含过期结论标注）
├── board-dts/
│   ├── rk3588-evb7-v11-standard.dts   板级设备树（当前基线）
│   ├── DTS-ALIGNMENT.md               与厂商标称 dts 的系统性比对
│   └── dts-diff-report.txt            比对原始输出
├── scripts/
│   ├── build/                    Dockerfile、build-rk3588.sh、repo 同步与 LFS
│   ├── dts/                      dts_diff.py、pin_audit.py
│   ├── flash/                    flash-rk3588.bat、RKDevTool config.cfg
│   ├── sceneboard/               SceneBoard 构建、预装修复、镜像检查、回退
│   └── board/                    串口取证、EDID 解析、光标库传输、wms 补丁源文件
├── images/                       parameter.txt、SHA256SUMS.txt、烧录说明（不含镜像）
└── evidence/                     板端与构建取证文本（已剔除大文件与二进制）
```

## 复现链路（TL;DR）

1. **准备源码**（构建机）：`repo init -u https://gitcode.com/ning-bb/manifest -b OpenHarmony-6.1-RK-LTS -m chipsets/rockchip.xml`，
   用 [scripts/build/sync.sh](scripts/build/sync.sh) 带重试同步，再用 [scripts/build/lfspull.sh](scripts/build/lfspull.sh) 拉 LFS。
2. **准备容器**：[scripts/build/Dockerfile](scripts/build/Dockerfile) 构建 `ohos-6.1-rk:jammy-v3`，以 1005:1005 运行。
3. **板级设备树**：把 [board-dts/rk3588-evb7-v11-standard.dts](board-dts/rk3588-evb7-v11-standard.dts)
   放回 `kernel/linux/linux-6.6/arch/arm64/boot/dts/rockchip/`，改完用 `scripts/dts/dts_diff.py` 复核。
4. **构建**：[scripts/build/build-rk3588.sh](scripts/build/build-rk3588.sh)，产物在 `out/rockchip/packages/phone/images/`。
5. **烧录**：`scripts/flash/flash-rk3588.bat`（必须在 RKDevTool 目录内启动），只改内核时只烧 `boot`。
6. **调试**：COM4 @1500000 8N1 拿 root shell；`hdc tconn <ip>:37827` 走网络；取证脚本见 [scripts/board](scripts/board)。

## 五条最重要的结论

1. **板级差异必须来自厂商固件设备树，不能靠试错。** DC-A588 的权威配置取自厂商官方固件
   `github.com/AndroidOL/Archive-DC-A588` 中的 `dtb-from-official-image/rk3588-evb7-lp4-v10.dts`；
   EVB7 dtsi 的默认配置在本板有 30+ 处错误（PCIe 供电、GMAC0/GMAC1、UART9 引脚冲突、状态灯引脚、DSI 幻影面板等）。
2. **U-Boot 静默不启动的根因是构建脚本的 shebang，不是硬件。** `decode_elf.py` 的 `#!/usr/bin/env python`
   在只有 `python3` 的环境里失败，`make_fit_atf.sh` 无 `set -e` 仍退出 0，产出缺 `atf` 节点的 FIT，
   SPL 打印 `cannot find image node 'atf-1': -1` 后跳转到未加载地址。
3. **DSI 幻影面板会让画面只占屏幕 56% 宽。** EVB7 默认开启 `dsi0` + `simple-panel-dsi`（1080×1920），
   无面板也 probe 成功，OH 显示合成器取到宽度 1080，而 HDMI 是 1920×1080。
4. **SceneBoard 的黑屏/停 Logo 是预装清单问题，不是板级问题。** BMS 走 `USE_PRE_BUNDLE_PROFILE` 清单安装，
   产品 `install_list.json` 缺少 `/system/app/SceneBoard`，同时旧 Launcher/SystemUI 被架构开关禁用。
5. **“看不到光标但点击有效”是 RS 屏幕映射错误。** 经典 WindowManager 的
   `InputWindowMonitor::UpdateDisplayInfo()` 漏填 `MMI::DisplayInfo.rsId`，光标被挂到没有画面的 RS 屏幕 0；
   桌面窗口走另一条正确映射路径，所以点击/hover 正常。

## 约定

- 板端所有结论都要有可复现的取证命令与原始输出，`evidence/` 中的 `.raw.txt` 是串口/HID 原样记录，
  同名 `.txt` 是去掉内核日志穿插后的可读副本。
- 不要用 `Test-NetConnection` 判断板卡在线：本机 FlClash TUN 会伪造 TCP 连通性。
- 串口 1500000 波特率下长输出会丢字，关键哈希一律用短命令分次读。
- 文档与脚本中的 `<BUILD_HOST>`、`<SSH_PORT>`、`<user>` 为环境相关占位符，复用时替换成自己的值。
