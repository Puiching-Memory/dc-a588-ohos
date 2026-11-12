# 01 · 板卡硬件

## 1. 整机与 SoC

| 项 | 值 |
| --- | --- |
| 载板 | 定昌电子 DC-A588-V04 |
| 核心板 | DC-CM3588 |
| SoC | RK3588 |
| 内存 | 8 GB LPDDR5（loader 实测 `ae2e6127e7e9bc6cea03d35918cbd1e9` 版本可正常初始化） |
| 存储 | eMMC 58.2 GiB |
| 调试串口 | 板载「调试口(ttyS2)」，`ttyFIQ0` 控制台，1500000 8N1 |
| 固件参考 | 厂商官方固件设备树 `github.com/AndroidOL/Archive-DC-A588` → `dtb-from-official-image/rk3588-evb7-lp4-v10.dts` |

## 2. 显示

- **HDMI OUT0 / OUT1**：两路输出。板上丝印把 **EDP0 / EDP1 与 HDMI OUT0 / OUT1 复用同一连接器**，
  本板按 HDMI 使用，与厂商固件一致（固件里 dp0/dp1/edp0/edp1 全 `disabled`）。
- **HDMI IN ×1**：热插拔检测在 DC-A588 上是 `GPIO2_B5`（EVB7 用 `GPIO1_D5`）。
- **MIPI DSI ×2**：FPC 0.5 mm 40P 座，无面板，整条链路关闭（见 [04-board-dts.md](04-board-dts.md)）。
- **LVDS**：未验证。

HDMI OUT1 走 VP1，引脚为 `GPIO3_C4/C5/C6`（CEC/DDC）与 `GPIO1_A6`（HPD）。

> **丝印编号 ≠ RS 屏幕 ID。** 实测鼠标光标被创建在 RS 屏幕 0、画面在 RS 屏幕 1，
> 切换物理端口恰好掩盖了映射错误。排查显示相关问题时不要用丝印推断 ID，见 [09-cursor-investigation.md](09-cursor-investigation.md)。

## 3. 网络

| | 控制器 | 说明 |
| --- | --- | --- |
| eth0 | GMAC0 `ethernet@fe1b0000` | 第一路 RJ45，RTL8211F，`rgmii-rxid`，PHY 地址 1，`tx_delay = 0x43` |
| eth1 | RTL8111（`pcie2x1l1` = `fe180000`） | 板载第二路 RJ45，PCIe 网卡，MAC 随机（无 EEPROM） |
| WLAN | mini-PCIe `pcie2x1l0`（`fe170000`） | 实测插的是 **RTL8852BE**（`10ec:b852`），非 4G 模块；树内无该芯片驱动，WiFi 当前不可用 |
| 4G | 同上 mini-PCIe 座 | 由 `vcc-3v8-4g`（`GPIO3_B4`，低有效，常开）供电，无模块可验证 |

注意 EVB7 dtsi 使能的是 `ethernet@fe1c0000`（gmac1），而本板只用 gmac0，且 gmac0 与 EVB7 的 `uart9`
引脚冲突，必须关闭 `&uart9`。

## 4. PCIe

| 节点 | 地址 | 本板用途 | reset | 供电 |
| --- | --- | --- | --- | --- |
| `pcie2x1l0` | `fe170000` | mini-PCIe 座（WiFi / 4G） | `GPIO1_B4` | `vpcie3v3-supply = vcc3v3_pcie`（`GPIO2_B4` 使能，`vin = vcc12v_dcin`，上电延时 5 ms），带 `rockchip,skip-scan-in-resume` |
| `pcie2x1l1` | `fe180000` | 板载 RTL8111 | `GPIO4_A2` | 另需 pinctrl `rtl8111-isolate`（`GPIO1_A4` pull-up，EVB7 dtsi 无此组） |
| `pcie3x4` / `pcie3x2` / `pcie2x1l2` / `pcie30phy` | — | 本板未引出 | — | 全部 `disabled` |

本板**无 PRSNT 在位检测引脚**。

> **PCIe 控制器缺 `vpcie3v3-supply` 会挂死 CPU**：读配置空间时 AXI 事务不返回，`rk-pcie` 线程停在
> `dw_pcie_read` 并触发 RCU stall，表现为整机卡住。这不是软件死循环。

## 5. 音频 / 按键 / 灯 / 蓝牙

| 功能 | 引脚 |
| --- | --- |
| 功放使能 `spk-con` | `GPIO1_D3`，高有效 |
| 耳机使能 `hp-con` | `GPIO1_D2`，高有效 |
| 耳机检测 `hp-det` | `GPIO1_C4` |
| 状态灯 `/leds/work` | **`GPIO3_B7`**（EVB7 用 `GPIO1_C6`，本板无引出；`GPIO3_B7` 在 EVB7 是 gmac1 PHY 复位，本板 gmac1 未引出） |
| 蓝牙 | UART8 → `/dev/ttyS8`，RTS = `GPIO3_A4`（EVB7 的 `GPIO4_C4` 在本板是 GMAC0 MDC） |

- `GPIO1_D2/D3` 与 EVB7 的 `vcc_mipicsi0/1`（摄像头供电）同脚，**摄像头与音频功放不能同时使用**；本板无摄像头，两个摄像头供电节点已 `disabled`。
- `GPIO1_C4` 在厂商固件的 `mark_gpio` 里是 `pwen`；与 `vcc-3v8-4g` 的 `gpio`（`GPIO3_B4`）同引脚同极性但命名不同，实际功能尚未核实。

## 6. 冲突清单（EVB7 默认配置在本板会踩到的引脚）

| EVB7 用途 | 占用 | 本板实际 |
| --- | --- | --- |
| `uart9m0_xfer` / `uart9m0_ctsn` | `GPIO2_C2` / `GPIO4_C5` | GMAC0 的 RXD1 / MDIO |
| `vcc_mipicsi0/1` | `GPIO1_D2` / `GPIO1_D3` | ES8388 功放 / 耳机使能 |
| `&i2c4` 上的 icm42607 | `GPIO4_C2` | GMAC0 RXDV |
| `&i2c5` 上 gt1x / hynitron | `GPIO3_C0` / `GPIO3_C1` | 本板无触摸屏，互相抢引脚 |
| `wireless_bluetooth` 的 `uart8m1_rtsn` | `GPIO4_C4` | GMAC0 MDC |

pinctrl 引脚是独占的：`uart8m1_xfer/ctsn` 只能给 `&uart8`，蓝牙节点只能声明 RTS 与 `bt_reset/wake/irq`，
否则会打印 `could not request pin N ... from group uart8m1-xfer` 并让 `rfkill_bt` probe 失败。

## 7. USB

- 三个 dwc3 控制器均已绑定：`fc000000.usb`、`fc400000.usb`、`fcd00000.usb`。
- 烧录用**载板下层 USB3.0 口（OTG）**。
- 实测 USB 鼠标挂在 `usbdrd3_1/fc400000.usb/.../usb3/3-1`，`usbhid` 绑定正常，MMI 能打开 `/dev/input/event7`。
- `usb_host` 服务自启动即 SIGSEGV、每 240 s 被 init 重启，属厂商 HDI 缺陷（`libusb_pnp_manager.z.so`
  的 `DdkListenerMgrAdd` 空指针），不影响内核 evdev 输入链路。

## 8. 输入设备基线（无指针设备时）

```
N: Name="bt-powerkey"                    H: Handlers=kbd event0 dmcfreq
N: Name="rk805 pwrkey"                   H: Handlers=kbd event1 dmcfreq
N: Name="headset-keys"                   H: Handlers=kbd event2 dmcfreq
N: Name="rockchip-es8388 Headset"        H: Handlers=event3
N: Name="adc-keys"                       H: Handlers=kbd event4 dmcfreq
N: Name="rockchip-hdmi0 rockchip-hdmi0"  H: Handlers=event5
N: Name="rockchip-hdmi1 rockchip-hdmi1"  H: Handlers=event6
```

存在 MMI 光标节点的前提是**有指针设备**；无鼠标时树上不存在 `CURSOR_NODE`，不能从画面推断光标位置。
