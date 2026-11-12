# 10 · 反复踩的坑

按「症状 → 根因 → 处置」记录，避免重复排查。

## 构建工具链

| 症状 | 根因 | 处置 |
| --- | --- | --- |
| 第三方库（`third_party/libnl`、`wpa_supplicant-2.9/libnl`）的 `config.h` / `defs.h` 不落盘，autotools 认为头文件没变化 | `prebuilts/ohos-sdk/linux/23/toolchains/diff` 是**桩程序**，恒返回 0 | 这些脚本前置 `PATH=/usr/bin:/bin:/usr/sbin:/sbin` |
| 第三方脚本报 `pushd: not found`（127）、`[ "$x" == y ]` 判定失效，且失败后仍报构建成功 | GN 用 `sh build.sh` 调用，`/bin/sh` 是 **dash**；调用常包在 `if ! func` 里，`set -e` 失效 | 改写为 POSIX 语法；不要依赖 `set -e`，显式检查返回值 |
| `iq_parser_v2/j2s4b` 报 `cannot find -lstdc++` | rkaiq 宿主工具用 `-m32` 链接 32 位 `libstdc++` | 镜像装 `g++-multilib` |
| 小系统产品构建失败：`service_shell_lite.c` 找不到 `ITrustedDeviceCb` / `SetCommand` | 本 manifest 的 dsoftbus 没有这些接口 | 小系统产品的 `config.json` 里直接移除 `distributedhardware` 子系统 |
| RK3588 无法生成 `update.img`，恒报 `Get image version failed` | 树内 `rkImageMaker` 与 `afptool` 不配套 | 放弃整包，用 RKDevTool 逐分区 + `config.cfg` 模板（RV1126B 工具配套，可整包） |
| U-Boot 无输出、SPL 后静默 | `decode_elf.py` 的 shebang 是 `#!/usr/bin/env python`，环境只有 `python3` | 改 `python3` 后重跑 `loader/rockchip/build_loader.sh`（详见 [05-flashing.md](05-flashing.md)） |

## 设备树 / 内核

| 症状 | 根因 | 处置 |
| --- | --- | --- |
| 读 PCIe 配置空间时 CPU 挂死、`rk-pcie` 停在 `dw_pcie_read`、RCU stall | 控制器缺 `vpcie3v3-supply`，AXI 事务不返回 | 补 `vpcie3v3-supply`；`dw_pcie_read` 只是 `readl`，不是软件死循环 |
| `could not request pin N ... from group uart8m1-xfer`，`rfkill_bt` probe 失败 | pinctrl 引脚独占，`&uart8` 与 `&wireless_bluetooth` 重复申请 | TX/RX/CTS 只给 `&uart8`；蓝牙 `pinctrl-0` 只放 RTS + `bt_reset/wake/irq` |
| `dwmmc_rockchip ... No normal/idle pinctrl state` | 驱动找 `"normal"`/`"idle"`，dtb 只定义 `"default"` | 所有 Rockchip 板都报，忽略 |
| 状态灯不亮 | `rockchip_standard_defconfig` 默认关 `CONFIG_LEDS_TRIGGER_HEARTBEAT` | 在 `rk3588_ohos.config` 补 `CONFIG_LEDS_TRIGGER_HEARTBEAT=y` |
| `watchdog_service` 每 10 s 退出 code 1，重试 4 次后等 240 s | `watchdog@feaf0000` disabled、无 `/dev/watchdog`，`init_watchdog.c` open 失败即返回 -1 | 不处理；要开必须同时确认能喂狗，否则变重启循环 |
| `r8169 ... rtl_nic/rtl8168h-2.fw (-2)` | 树内无 linux-firmware，`CONFIG_EXTRA_FIRMWARE=""`，`fw_path` 仅 `/lib/firmware*` | 镜像内置固件或 `CONFIG_EXTRA_FIRMWARE` 编进内核；无固件时千兆稳定性未验证 |
| `ahci-dwc ... supply ahci/phy/target not found, using dummy regulator` | `rk3588s.dtsi` 的 SATA 节点本就没有这三路 supply | 厂商内核同样报，忽略 |
| 画面只占屏幕 56% 宽 | EVB7 dtsi 默认开 `dsi0` + `simple-panel-dsi`，无面板也 probe 成功 | 关闭 `dsi0` / `route_dsi0` / `mipi_dcphy0` |
| `rk860x ... vsel-gpios- not found` 出现在 `Starting kernel ...` 之前 | 来自 **U-Boot** `rk860x_regulator.c`，内核树无此字符串 | 忽略 |
| 本地没有 `dtc`、也没有 python `libfdt` | 宿主未装 | 用 `out/kernel/OBJ/linux-6.6/scripts/dtc/dtc` |

## Windows / 网络

| 症状 | 根因 | 处置 |
| --- | --- | --- |
| 任意端口都「可连」，`Test-NetConnection` 对不可达地址也返回成功 | FlClash TUN 伪造 TCP 连通性 | 看是否有从物理网卡地址发出的 `SynSent`，或 `route add <网段> 172.16.0.8` 绕开 TUN 后复测 |
| 远程命令里的双引号消失 | PowerShell 单引号串在 native 传参时吞掉 `"` | 远程命令避免双引号；复杂脚本本地写好 `scp` 过去执行 |
| `scp` 显示 100% 但文件还在传 | Windows 的 `scp` 走 SFTP，`ftruncate` 先撑到源大小 | 按进程启动时间与速率估算，或改 `rsync` |
| 同一 shell 里跑 `for ... sleep` 后读到的输出都是循环中间态 | 循环占住了该 shell | 长任务走后台异步，结束再发下一条 |
| 中文 Git 输出乱码 | 控制台编码 | 显式 UTF-8；需保持原文时按字节读写 |

## 板端

| 症状 | 根因 | 处置 |
| --- | --- | --- |
| `hdc list targets` 有 `COM4`，`-t COM4` 报 `Device not found` | COM4 是假目标（FTDI 调试串口） | 用 `hdc tconn <ip>:37827` |
| 读串口拿不到 shell | hdc server 独占 COM4 | 先 `hdc kill` |
| hdc 周期性断开 | `usb_host` SIGSEGV 重启循环 | `hdc kill` + `tconn` 重试，`Connect failed` 等 20 s |
| `hdc shell 'nohup ... &'` 挂住不返回 | 三个 fd 未全部重定向 | `>/dev/null 2>&1 </dev/null &` |
| 串口长输出缺字 | 1500000 波特率下丢字节 | 短命令分次读；关键哈希单独读 |
| 脚本用了 `tr` / `awk` 失败 | toybox 无这两个命令（有 `sqlite3`、`power-shell`） | 自带解码器（`serial_file_receiver.c`）或改用 `sed`/`power-shell` |
| `bm dump` / `hidumper` 被拒绝 | UART shell 权限不足 | 不能当作包未安装的证据，改用只读 SQLite 查询 |
| `hiview` 的 `sys_event_db/*.db` 打开报 `file is not a database` | 不是 sqlite 格式 | 换取证途径 |
| 串口传大文件校验失败 | 长传输无逐块回执，缓冲溢出 | 用 `Send-BoardCursorReliable.ps1`（512 字节块 + `RAW_ACK` + sha256） |
| `power-shell timeout` 重设后失效 | 参数不持久 | 每次重启后重设 |

## 仓库 / 镜像管理

- 镜像总体积约 4.3 GB（`system.img` 2 GB + `userdata.img` 1.4 GB + `vendor.img` 268 MB），
  **不进 Git**；仓库只保留 `parameter.txt`、`SHA256SUMS.txt` 与说明。
- Windows 上克隆后中文文件名可能显示为八进制转义，`git config core.quotepath false` 即可。
- 对比不同构建版本时以 **dtb 哈希**为准（`Image`/`boot.img` 含编译时间戳，每次都会变）。
