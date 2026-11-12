# 05 · 镜像烧录

## 1. 烧录包

本仓库不含镜像（`system.img` 2 GB、`userdata.img` 1.4 GB）。工作机上的交付目录结构：

```
ohos-rk3588-images\
├── images\                     烧录用镜像，SHA256SUMS.txt + parameter.txt 已收录到本仓库 images/
├── rktools\
│   ├── RKDevTool\              v3.37，config.cfg 已预置（副本在 scripts/flash/config.cfg）
│   └── DriverAssitant_v5.14\   USB 驱动安装程序（DriverInstall.exe）
├── backups\                    各实验前的镜像备份
├── images-sceneboard-20261105\ R1 快照
└── flash-rk3588.bat            一键启动（副本在 scripts/flash/）
```

## 2. 分区表（`images/parameter.txt`）

```
0x4000@0x2000(uboot)       0x20000@0x6000(boot)       0x2000@0x26000(misc)
0x1000@0x28000(bootctrl)   0x400000@0x29000(system)   0x200000@0x429000(vendor)
0x19000@0x629000(sys-prod) 0x19000@0x642000(chip-prod) 0x10000@0x65B000(updater)
0x8000@0x66B000(eng_system) 0x8000@0x673000(eng_chipset) 0x20000@0x67B000(chip_ckm)
-@0x69B000(userdata:grow)
```

`bootctrl`、`eng_chipset`、`chip_ckm` 三行没有对应镜像，保持不勾选；缺失不影响首次启动。

## 3. RKDevTool 使用

1. 装驱动：`rktools\DriverAssitant_v5.14\DriverInstall.exe`。
2. USB 线接载板**下层 USB3.0 口（OTG）**。
3. 按住「升级&复位键」不放，再上电 → 工具出现 `MASKROM` 或 `LOADER` 设备。
4. 双击 `flash-rk3588.bat`（或直接启动 `rktools\RKDevTool\RKDevTool.exe`）。

> **必须在工具目录内启动。** RKDevTool 按*当前工作目录*读取 `config.cfg`，从快捷方式或上级目录启动会生成
> 一份 639 字节的空配置，表格里只剩一行 `Loader`。`flash-rk3588.bat` 已先 `cd /d` 到工具目录。
> 表格为空时也可右键 →「导入配置」→ 选 `rktools\config_generated.cfg`（= `config.good.bak`）。

## 4. 常见烧录场景

| 场景 | 勾选 | 备注 |
| --- | --- | --- |
| 只改内核 / dts | `uboot` 不动，只烧 `boot` | boot 是 FIT（内核+ramdisk+DTB），地址 `0x6000` |
| 只改预装配置 / 系统应用 | 只烧 `system`，地址 `0x29000` | 可保留 Userdata |
| 全量 | 全勾（除三行无镜像分区） | 会清 Userdata |
| 补 U-Boot（ATF 缺失） | 只烧 `uboot`，地址 `0x2000` | loader 与其余分区正常时不必重刷 |

## 5. U-Boot 静默不启动（已修复，重要）

**现象**：串口打印到 `Total: 130.10/492.50 ms` 后完全静默，按键无响应，HDMI 无信号。

**根因**：`loader/u-boot/arch/arm/mach-rockchip/decode_elf.py` 的 shebang 是 `#!/usr/bin/env python`，
构建环境只有 `python3`。`gen_elf_nodes` 失败返回 1，`make_fit_atf.sh` **没有 `set -e`** 仍退出 0，
于是 FIT 的 `configurations` 写了 `firmware = "atf-1"` 却没有 atf 节点。
SPL 打印 `cannot find image node 'atf-1': -1` 后跳转到未加载地址。

**修复**：

```bash
sed -i '1s|.*|#!/usr/bin/env python3|' loader/u-boot/arch/arm/mach-rockchip/decode_elf.py
bash loader/rockchip/build_loader.sh        # 重新打包 uboot.img
```

验证：`uboot.img` 的 FIT 内应含 `atf-1/2/3`。

## 6. loader 与镜像版本

| 文件 | 状态 |
| --- | --- |
| `MiniLoaderAll.bin` | md5 `ae2e6127e7e9bc6cea03d35918cbd1e9`，已验证可初始化 LPDDR5 并启动 SPL |
| `uboot.img`（含 ATF） | 重新打包版，md5 `5a39351493f0f5527d3c7e1b19cd2fa5`，FIT 内含 `atf-1/2/3` |
| 当前交付 `boot.img` | SHA256 `2d0ded4377213019bbf40fce5423c4090316bc066a765612b396d7458f1a74cf` |
| 当前交付 `system.img` | SHA256 `62ae221436cd3b36289da08ccc86591e1415e81d4193ec433119b4598388a0e9`（经典 WindowManager 基线） |

全部 14 个文件的校验值见 [images/SHA256SUMS.txt](../images/SHA256SUMS.txt)，用
`Get-FileHash -Algorithm SHA256` 或 `sha256sum -c` 核对。

## 7. 避免的坑

- **不要用 `update.img` 整包**：树里 `rkImageMaker` 与 `afptool` 不配套，恒报 `Get image version failed`。
  RK3588 用 RKDevTool 逐分区 + `config.cfg` 模板；RV1126B 的工具配套，可整包。
- RKDevTool 的「强制按地址写」要勾，地址按 `parameter.txt` 校正。
- 回退到经典版本时**必须同时烧配套的 `boot` 与 `system`**：只烧其中一个会得到「新 system + 旧 boot」
  或反之的混合状态。
