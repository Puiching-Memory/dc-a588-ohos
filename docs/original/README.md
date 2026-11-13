# OpenHarmony 6.1-RK-LTS · RK3588 镜像

> 归档说明：以下是历史阶段记录，后续状态以 [SceneBoard 实验汇总](../08-sceneboard-experiment.md) 和 [光标调查](../09-cursor-investigation.md) 为准；本地镜像恢复不代表已完成板上回退。

内核镜像 2026-11-03 07:01 构建，`uboot.img` 于 09:44 重新打包（补入 ATF，见「已知问题」）。
构建机：`<BUILD_HOST>`，产物目录 `~/ohos/src/out/rockchip/packages/phone/images`。

## 目录结构

```
ohos-rk3588-images\
├── images\                        烧录用镜像（RKDevTool 配置指向这里）
│   ├── MiniLoaderAll.bin          547 KB   loader（DDR 初始化 + SPL）
│   ├── parameter.txt              535 B    GPT 分区表
│   ├── uboot.img                  4 MB     U-Boot proper + ATF + OP-TEE 的 FIT
│   ├── boot.img                   48.6 MB  FIT：内核 + ramdisk + DTB
│   ├── system.img                 2.0 GB   系统分区
│   ├── vendor.img                 268 MB   厂商分区
│   ├── sys_prod.img               52 MB    系统产品分区
│   ├── chip_prod.img              52 MB    芯片产品分区
│   ├── userdata.img               1.4 GB   用户数据（grow）
│   ├── updater.img                22 MB    升级分区
│   ├── eng_system.img             12 MB    工程模式系统分区
│   ├── ramdisk.img                2.8 MB   已包含在 boot.img 内
│   ├── Image                      44.3 MB  独立内核，供调试
│   └── rk3588-evb7-v11-standard.dtb 203 KB 独立设备树，供调试
├── rktools\
│   ├── RKDevTool\                 RKDevTool v3.37，config.cfg 已预置
│   └── DriverAssitant_v5.14\      USB 驱动安装程序（DriverInstall.exe）
├── _archive\                      旧整包 tar（含未修 ATF 的 uboot.img，勿用）
└── flash-rk3588.bat               一键启动 RKDevTool
```

`images\SHA256SUMS.txt` 是校验清单（已按本次修复后的文件重新生成），
可用 `Get-FileHash` 逐项比对。

## 快速烧录

双击根目录的 `flash-rk3588.bat`，或直接双击 `rktools\RKDevTool\RKDevTool.exe`。

**必须在工具目录内启动。** RKDevTool 按*当前工作目录*读取 `config.cfg`，
从别处启动（快捷方式、从上级目录运行）会生成一份 639 字节的空配置，
表格里只剩一行 `Loader`。`flash-rk3588.bat` 已先 `cd /d` 到工具目录再启动，
用它不会有这个问题。

启动后下载镜像表格已按 `images\` 填好文件名，无需再手动选路径。
若表格仍为空，右键表格 →「导入配置」→ 选 `rktools\config_generated.cfg`；
`rktools\config.good.bak` 是同一份配置的备份。

进不了 loader 时先装驱动：`rktools\DriverAssitant_v5.14\DriverInstall.exe`。

**只补 U-Boot（当前场景）**

只烧 `uboot` 分区即可，loader 与其余分区都正常：

1. USB 线接板上**下层 USB3.0 口**（OTG）到 PC
2. 按住「升级&复位键」不放，再上电 → 工具显示 `MASKROM` 或 `LOADER` 设备
3. 下载镜像页只勾选 `uboot` 行 → 执行

**全量烧录**

勾选全部行执行。`bootctrl`、`eng_chipset`、`chip_ckm` 三行没有对应镜像，
保持不勾选；这些分区缺失不影响首次启动。

## loader 与镜像版本

| 文件 | 状态 |
| --- | --- |
| `MiniLoaderAll.bin` | 07:00 构建版本（md5 `ae2e6127e7e9bc6cea03d35918cbd1e9`），已验证可正常初始化 LPDDR5 并启动 SPL |
| `uboot.img` | 09:44 重新打包（md5 `5a39351493f0f5527d3c7e1b19cd2fa5`），FIT 内含 `atf-1/2/3` |

## 已知问题

**U-Boot proper 无输出、屏幕无信号（已修复）**

现象：串口打印到 `Total: 130.10/492.50 ms` 后完全静默，按键无响应，HDMI 无信号。

原因：`loader/u-boot/arch/arm/mach-rockchip/decode_elf.py` 的 shebang 是
`#!/usr/bin/env python`，构建环境只有 `python3`。`gen_elf_nodes` 执行失败返回 1，
`make_fit_atf.sh` 没有 `set -e` 仍退出 0，于是生成的 FIT 里
`configurations` 写了 `firmware = "atf-1"` 却没有任何 atf 节点。
SPL 打印 `cannot find image node 'atf-1': -1` 后跳转到未加载的地址。

修复：shebang 改为 `python3`，重跑 `loader/rockchip/build_loader.sh` 重新打包。

## 分区表（parameter.txt）

```
0x4000@0x2000(uboot)      0x20000@0x6000(boot)      0x2000@0x26000(misc)
0x1000@0x28000(bootctrl)  0x400000@0x29000(system)  0x200000@0x429000(vendor)
0x19000@0x629000(sys-prod) 0x19000@0x642000(chip-prod) 0x10000@0x65B000(updater)
0x8000@0x66B000(eng_system) 0x8000@0x673000(eng_chipset) 0x20000@0x67B000(chip_ckm)
-@0x69B000(userdata:grow)
```

## 源码与构建环境

- manifest：`https://gitcode.com/caesar-wang/manifest`，分支 `OpenHarmony-6.1-RK-LTS`，`chipsets/rockchip.xml`
- 产品：`rk3588`（standard / arm64），内核 `linux-6.6`，dts `rk3588-evb7-v11-standard`
- 构建容器 `ohos-6.1-rk:jammy-v3`（Ubuntu 22.04 + g++ + g++-multilib），入口 `~/ohos/build-rk3588.sh`
- SDK：OpenHarmony 6.1-LTS API 23，位于 `prebuilts/ohos-sdk/linux/23`
- 串口：`ttyS2`（板载「调试口(ttyS2)」），1500000 8N1
