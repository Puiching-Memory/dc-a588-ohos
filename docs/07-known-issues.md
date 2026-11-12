# 07 · 已知问题总表

严重度：**P0** 阻断产品化 / **P1** 功能不可用或未验证 / **P2** 体验或稳定性风险 / **P3** 噪音。
状态基线：经典 WindowManager 版本（`boot.img` `2d0ded43…`、`system.img` `62ae2214…`）。
逐条证据与日志原文见 [original/KNOWN-ISSUES.md](original/KNOWN-ISSUES.md)。

## 显示

| ID | 问题 | 严重度 | 根因 | 状态 |
| --- | --- | --- | --- | --- |
| D1 | 画面只占面板左侧约 56% 宽，右侧纯黑，鼠标进不去 | **P0** | EVB7 dtsi 默认开启 `dsi0` + `simple-panel-dsi`（1080×1920），无面板也 probe 成功，OH 取到宽度 1080 而 HDMI 是 1920 | 已修（dts 关闭 `dsi0`/`route_dsi0`/`mipi_dcphy0`） |
| D2 | U-Boot 阶段两路 HDMI probe 失败 `can't get link_clk` | P3 | dtb `clock-names` 11 项、`clocks` 10 对；内核用 `devm_clk_get_optional` 容忍，U-Boot 不容错 | 不处理 |
| D3 | `route-hdmi0/1: failed to get logo,offset` | P3 | 无 logo 分区 | 不处理 |
| D4 | `[drm] failed to init overlay plane Cluster0..3-win1` ×4 | P3 | overlay 平面窗口被占用/带宽不足 | 不处理，主平面正常 |
| D5 | `drm-cubic-lut@0` 保留内存失败 | P3 | 节点 base 为 0 | 不处理 |
| D6 | HDMI-IN / DP 声卡 deferred probe | P2 | 依赖显示通路未就绪；HDMI-IN 检测脚已改 GPIO2_B5 但未接信号源 | 未验证 |
| D7 | HDMI OUT1、DSI、LVDS、eDP 面板未验证 | P1 | 无面板与线材；DSI/LVDS 无 EDID | HDMI1 已验证绑定出图；DSI0 关闭；DP 与厂商一致关闭 |

## 网络

| ID | 问题 | 严重度 | 根因 | 状态 |
| --- | --- | --- | --- | --- |
| N1 | eth0 只协商到 100 Mbps | **P1** | 待定：交换机口百兆 / 4 芯网线 / `tx_delay=0x43` 不适配千兆 | 未解决，需换千兆口与网线复测 |
| N2 | eth1（RTL8111）无链路 | P1 | 未插网线 | 待测 |
| N3 | `rtl_nic/rtl8168h-2.fw` 加载失败 | P2 | 树内无 linux-firmware，`CONFIG_EXTRA_FIRMWARE=""`，`fw_path` 仅 `/lib/firmware*` | 未处理；链路可起，千兆稳定性未验证 |
| N4 | eth1 MAC 每次随机 | P2 | RTL8111 无 EEPROM | 开发阶段不处理，量产需固定方案 |
| N5 | WLAN 驱动与实际硬件不匹配 | **P1** | dts 沿用 EVB7 的 AP6xxx 配置；mini-PCIe 上实际是 RTL8852BE（`10ec:b852`），树内无驱动 | 未解决，WiFi 不可用 |
| N6 | 4G 模块未验证 | P1 | 无模块 | 未验证 |
| N7 | U-Boot 无网络 | P3 | `ethernet@fe1c0000` 在板级 dts 中 disabled | 不处理 |

## 存储

| ID | 问题 | 严重度 | 根因 | 状态 |
| --- | --- | --- | --- | --- |
| S1 | TF 卡未验证 | P1 | 卡槽为空；SD 节点与厂商 dts 逐字段一致 | 待插卡 |
| S2 | `No normal/idle pinctrl state` | P3 | 驱动找 `"normal"`/`"idle"`，dtb 只有 `"default"` | 不处理，所有 Rockchip 板同样 |
| S3 | SATA 供电 dummy regulator | P3 | `rk3588s.dtsi` 的 SATA 节点本就没有三路 supply | 不处理 |
| S4 | SATA 盘未验证 | P1 | 未接硬盘 | 未验证 |

## 音频 / 蓝牙

| ID | 问题 | 严重度 | 根因 | 状态 |
| --- | --- | --- | --- | --- |
| A1 | ES8388 未实际出声 | P1 | 未做播放测试 | 未验证 |
| A2 | 大量 `/dev/snd/controlC0` AVC denial | P3 | SELinux 策略未覆盖该 ioctl，当前 permissive 不阻断 | 转 enforcing 前必须补策略 |
| B1 | 蓝牙协议栈未验证 | P1 | 仅到驱动层 | 未验证 |
| B2 | `rkgpiod_request failed to request BT,power gpio` | P3 | dts 未定义该可选属性，厂商 dts 也没有 | 不处理 |

## 内核 / 启动

| ID | 问题 | 严重度 | 根因 | 状态 |
| --- | --- | --- | --- | --- |
| K1 | 硬件看门狗未启用，`watchdog_service` 每 10 s 退出 | P2 | `watchdog@feaf0000` disabled，无 `/dev/watchdog`，`init_watchdog.c` open 失败即返回 -1 | 未处理；开启必须单独验证喂狗，否则变重启循环 |
| K2 | 未使用的 imx415 摄像头 dtsi 被引入 | P3 | 板级 dts `#include "rk3588-evb7-v11-imx415.dtsi"` | 已移除 include（需确认 `rk3588-standard.dtsi` 无引用） |
| K3 | `rk860x ... vsel-gpios- not found` | P3 | 来自 U-Boot，内核树无此字符串 | 不处理 |
| K4 | U-Boot 先试 SD 再回落 eMMC | P3 | 启动顺序 MMC2(SD)→MMC1(eMMC)，`mmc init failed -95` | 不处理，仅增加启动耗时 |
| K5 | 未识别的内核命令行参数 | P3 | 部分参数给用户态用 | 不处理 |
| K6 | `init.usb.configfs.cfg` 缺失 | P2 | 产品未安装该配置文件，影响 USB gadget（hdc over USB） | 未处理 |
| K7 | `SubInitRun 0` / DAC 告警 | P3 | 常规告警 | 不处理 |
| K8 | `access_tokenid_ioctl: magic fail` 刷屏 | P3 | 调试输出，每秒数十条 | 调试时 `dmesg -n` 降噪 |
| K9 | `usb2-phy ... illegal mode` | P3 | USB2 PHY 模式未设置 | USB 主机/设备模式未完整验证 |
| K10 | `hungtask_user` / XCollie kick | P3 | OH 用户态看门狗正常动作 | 不处理 |
| K11 | `usb_host` SIGSEGV 重启循环 | P2 | 厂商 HDI `libusb_pnp_manager.z.so` 的 `DdkListenerMgrAdd` 空指针，`Process life time:1s` | 未定位；内核 evdev 输入链路不受影响 |

## 工程 / 产品化

| ID | 问题 | 严重度 | 根因 | 状态 |
| --- | --- | --- | --- | --- |
| P1 | SELinux permissive | **P1** | 产品配置 `selinux_adapter_enforce=false` | 量产前必须转 enforcing 并补策略 |
| P2 | eng 模式开启 | **P1** | 内核命令行含 `ohos.boot.eng_mode=on` | 量产前关闭 |
| P3 | 串口 root shell 开启 | **P1** | `base/startup/init/services/etc/console.cfg` 改为 `start-mode: boot` / `disabled: 0` | **发布前必须回滚**（原文件备份在 `/tmp/console.cfg.orig`） |
| P4 | hdc over USB 不可用 | P2 | USB OTG 未接主机或工作在 host 模式；另见 K6 | 未解决；网络 hdc 可用 |
| P5 | 构建产物不可复现 | P3 | 内核 `Image` 内嵌编译时间戳 | 对比版本以 dtb 哈希为准 |
| P6 | 未映射外设：CAN、RTC（hym8563）、4×UART、LVDS/eDP 面板与背光、HDMI-IN | P1 | 无资料或无硬件 | 需厂商原理图/规格书，不靠试错 |
| P7 | 内存与温度余量未测 | P2 | 未做压测 | 未开始 |

## 光标（独立专项）

- 「看不到光标但点击有效」的根因是 WindowManager 漏填 `MMI::DisplayInfo.rsId`，
  修正库已编译未上板。详见 [09-cursor-investigation.md](09-cursor-investigation.md)。
- 硬件光标在本板不可用：Rockchip VDI 的 `GetDisplayProperty` 是无条件桩、`UpdateHardwareCursor` 无产品实现、
  DRM 合成路径无光标平面绑定。目前始终走软件光标 `MoveSoft()`。
