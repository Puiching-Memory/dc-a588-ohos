# 04 · 板级设备树适配

板级 dts 文件：`board-dts/rk3588-evb7-v11-standard.dts`
放回源码：`kernel/linux/linux-6.6/arch/arm64/boot/dts/rockchip/`（与 `rk3588-evb7-v11.dtsi`、
`rk3588-standard.dtsi` 同目录）。

## 1. 流程

1. 从厂商官方固件中取设备树：`github.com/AndroidOL/Archive-DC-A588` 的
   `dtb-from-official-image/rk3588-evb7-lp4-v10.dts` 反编译结果，作为本板的**权威引脚依据**。
2. 以 `rk3588-evb7-v11-standard.dts` 为基线（同 SoC、同 QP HDMI），**只覆写差异**，不改原厂 dtsi。
3. 改完先做离线语法/引用校验，再构建，再看串口日志，最后跑 `dts_diff.py` 比对还差哪些开关。
4. 只有引脚层面的差异才算 bug；`status` 开关差异多数是「多开了无关驱动」，会影响启动时间与日志噪音。

离线校验（没有 `dtc` 命令时用构建产物里的）：

```bash
cpp -nostdinc -I include -I arch/arm64/boot/dts -undef -D__DTS__ -x assembler-with-cpp \
    arch/arm64/boot/dts/rockchip/rk3588-evb7-v11-standard.dts > /tmp/final.dts
out/kernel/OBJ/linux-6.6/scripts/dtc/dtc -I dts -O dtb -o /tmp/final.dtb /tmp/final.dts
```

反编译核对用 `dtc -I dtb -O dts`；`#include` 里的宏已展开成裸数字，phandle 需要自行反推
（`pin_audit.py` 就是做这件事：alias → phandle → GPIO bank/pin 解码）。

## 2. 覆写清单与理由

### 2.1 供电与电源使能

```dts
vcc3v3_pcie: vcc3v3-pcie {          /* mini-PCIe 3.3V：GPIO2_B4 使能，上电延时 5ms */
    compatible = "regulator-fixed";
    enable-active-high;
    gpios = <&gpio2 RK_PB4 GPIO_ACTIVE_HIGH>;
    startup-delay-us = <5000>;
    vin-supply = <&vcc12v_dcin>;
};

vcc_3v8_4g: vcc-3v8-4g {            /* 4G 模块 3.8V：GPIO3_B4，低有效，常开 */
    regulator-boot-on;
    regulator-always-on;
    gpio = <&gpio3 RK_PB4 GPIO_ACTIVE_LOW>;
};
```

`vcc3v3_pcie` **必须**挂到 `&pcie2x1l0` 的 `vpcie3v3-supply`，否则读配置空间会挂死 CPU。

### 2.2 音频

```dts
&es8388_sound {
    spk-con-gpio = <&gpio1 RK_PD3 GPIO_ACTIVE_HIGH>;
    hp-con-gpio  = <&gpio1 RK_PD2 GPIO_ACTIVE_HIGH>;
};
```

EVB7 把 `GPIO1_D2/D3` 给了 `vcc_mipicsi0/1`（摄像头供电），本板用于功放/耳机，
因此同时把摄像头两路供电 `disabled`。

### 2.3 状态灯

```dts
&{/leds/work} {
    gpios = <&gpio3 RK_PB7 GPIO_ACTIVE_HIGH>;   /* EVB7 是 GPIO1_C6，本板无引出 */
    pinctrl-names = "default";
    pinctrl-0 = <&work_led_gpio>;
};
```

另外需要在 `arch/arm64/configs/rk3588_ohos.config` 打开 `CONFIG_LEDS_TRIGGER_HEARTBEAT=y`，
否则默认触发器无效、灯常灭。

### 2.4 蓝牙（UART8）

```dts
&uart8 {
    pinctrl-names = "default";
    pinctrl-0 = <&uart8m1_xfer &uart8m1_ctsn>;   /* TX/RX/CTS 由 uart8 独占 */
    status = "okay";
};

&wireless_bluetooth {
    bt_port = "/dev/ttyS8";
    uart_rts-gpios = <&gpio3 RK_PA4 GPIO_ACTIVE_LOW>;   /* EVB7 的 GPIO4_C4 在本板是 GMAC0 MDC */
    pinctrl-names = "default", "rts_gpio";
    pinctrl-0 = <&uart8m1_rtsn &bt_reset_gpio &bt_wake_gpio &bt_irq_gpio>;
    pinctrl-1 = <&uart8_rts_gpio>;
};
```

两个设备同时 `request uart8m1-xfer` 会让蓝牙 probe 失败，所以蓝牙节点只声明 RTS 与三个控制脚。

### 2.5 以太网

```dts
&gmac0 {
    phy-mode = "rgmii-rxid";
    clock_in_out = "output";
    snps,reset-gpio = <&gpio4 RK_PB3 GPIO_ACTIVE_LOW>;
    snps,reset-active-low;
    snps,reset-delays-us = <0 20000 100000>;
    tx_delay = <0x43>;
    phy-handle = <&rgmii_phy0>;
    status = "okay";
};
&gmac1 { status = "disabled"; };
```

配套关闭 EVB7 里占用 gmac0 引脚的两组节点：

```dts
&vcc3v3_lcd_n { /delete-property/ gpio; };   /* 该 gpio 在本板属于 GMAC0 */
&i2c4 { status = "disabled"; };              /* icm42607 占 GPIO4_C2 = gmac0 RXDV */
&uart9 { status = "disabled"; };             /* uart9m0_xfer/ctsn 占 GPIO2_C2 / GPIO4_C5 */
```

### 2.6 SD / SDIO / 触摸 / 摄像头

```dts
&sdio { status = "disabled"; };                       /* 无 SDIO WiFi，mini-PCIe 上是 RTL8852BE */
&vcc_3v3_sd_s0 {                                       /* TF 卡固定 3.3V，缺电压约束会 could not set regulator OCR */
    regulator-min-microvolt = <3300000>;
    regulator-max-microvolt = <3300000>;
};
&vcc_mipicsi0 { status = "disabled"; };
&vcc_mipicsi1 { status = "disabled"; };
&i2c5 { status = "disabled"; };                        /* 无触摸屏；gt1x 与 hynitron 抢 GPIO3_C0/C1 */
```

SD（`mmc@fe2c0000`）与厂商 dts 逐字段一致：无 `cd-gpios`、`no-sdio/no-mmc/disable-wp/sd-uhs-sdr104`。
无卡时只打印 `Bus speed = 400000Hz`，不会有卡枚举日志。

### 2.7 HDMI-IN 检测脚

```dts
&{/hdmirx-controller@fdee0000} {
    hdmirx-det-gpios = <&gpio2 RK_PB5 GPIO_ACTIVE_LOW>;   /* EVB7 用 GPIO1_D5 */
};
```

### 2.8 PCIe

```dts
&pcie2x1l0 {                                    /* mini-PCIe 座 */
    status = "okay";
    reset-gpios = <&gpio1 RK_PB4 GPIO_ACTIVE_HIGH>;
    vpcie3v3-supply = <&vcc3v3_pcie>;
    rockchip,skip-scan-in-resume;
};

&pcie2x1l1 {                                    /* 板载 RTL8111 */
    status = "okay";
    reset-gpios = <&gpio4 RK_PA2 GPIO_ACTIVE_HIGH>;
    pinctrl-names = "default";
    pinctrl-0 = <&rtl8111_isolate>;             /* GPIO1_A4 pull-up，EVB7 dtsi 无此组 */
};

&pcie3x4  { status = "disabled"; };
&pcie3x2  { status = "disabled"; };
&pcie2x1l2{ status = "disabled"; };
&pcie30phy{ status = "disabled"; };
```

### 2.9 显示输出

```dts
&hdmi1        { status = "okay"; };    /* HDMI OUT1 → VP1 */
&hdmi1_sound  { status = "okay"; };
&route_hdmi1  { status = "okay"; };
&hdptxphy_hdmi1 { status = "okay"; };

&dp0 { status = "disabled"; };         /* 与 HDMI OUT0 复用同一连接器，厂商固件同样关闭 */
&dp1 { status = "disabled"; };
&dp0_sound { status = "disabled"; };
&dp1_sound { status = "disabled"; };

&dsi0        { status = "disabled"; }; /* 关键：见下 */
&route_dsi0  { status = "disabled"; };
&mipi_dcphy0 { status = "disabled"; };
```

**DSI 幻影面板（P0 已修复）**：EVB7 dtsi 默认开启 `dsi0` 并挂 `simple-panel-dsi`
（`hactive=1080`、`vactive=1920`、像素时钟 132 MHz）。该 panel 不需要 i2c 探测，本板 DSI 座空置也照样
probe 成功，DRM 里多出一个不存在的 1080×1920 显示器；OH 显示合成器取到宽度 1080，
而 HDMI 实际 1920×1080，表现为**画面只占左侧约 56% 宽、右侧纯黑、鼠标进不去**。
日志特征：`panel-simple-dsi fde20000.dsi.0: Expected bpc in {6,8} but got: 0`、`bound fde20000.dsi`。

## 3. 与厂商 dts 的系统性比对

工具：`scripts/dts/dts_diff.py`（对比两侧节点 `status`、GPIO 属性解码值、单侧独有 GPIO 节点）。
原始输出：`board-dts/dts-diff-report.txt`。结论摘要（我方 1235 节点，厂商 1017，共有 976）：

- **19 项双方共有的 GPIO 属性逐项一致**，包括状态灯 `GPIO3_B7`、`vcc3v3-pcie` `GPIO2_B4`、
  `vcc-3v8-4g` `GPIO3_B4`、两路 PCIe reset、ES8388 功放/耳机、gmac0 reset、HDMI 使能等。
- **6 处「少开」**（厂商 okay，我们 disabled）：`can@fea50000`、3 个 UART、`pwm@febf0020`、
  `watchdog@feaf0000`，以及我方完全没有的 `hdmiin-sound`。其中 CAN / UART / PWM / 看门狗属于真实功能缺失。
- **27 处「多开」**：来自 `rk3588-evb7-v11-imx415.dtsi`（11 个摄像头节点）、EVB7 默认的 HDMI1/DP 相关
  节点、以及多媒体/低功耗策略差异。多数无功能影响，但会 probe 无关驱动、刷日志（imx415 会刷
  `rkcif_update_sensor_info ... get remote sensor_sd failed`）。
  已删除该 imx415 include（需确认 `rk3588-standard.dtsi` 无引用）。
- 仍待核实：`GPIO3_B4` 的实际用途（厂商 `mark_gpio.pwen` vs 4G 供电）、本板是否有风扇
  （厂商有 `/fan-regulator` `GPIO4_A5`）。

用法：

```bash
python3 scripts/dts/dts_diff.py <我方.dts> <厂商.dts>     # 反编译后的 dts
python3 scripts/dts/pin_audit.py <我方.dts>               # GPIO alias → phandle → bank/pin 汇总
```

## 4. 已知遗留的 dts 噪音

| 日志 | 结论 |
| --- | --- |
| `rk860x_regulator ... vsel-gpios- not found` | 来自 **U-Boot**，内核树无此字符串，可忽略 |
| `dwmmc_rockchip ... No normal/idle pinctrl state` | 驱动找 `"normal"`/`"idle"`，dtb 只定义 `"default"`，所有 Rockchip 板都报 |
| `ahci-dwc ... supply ahci/phy/target not found` | RK3588 SATA 常态，厂商内核同样 |
| `rockchip_dw_hdmi_qp_probe: can't get link_clk` | U-Boot 用 `clk_get_by_name` 不容错，RK3588 HDMI TX 无该时钟；分区表无 logo 分区，不处理 |
| `[drm] failed to init overlay plane Cluster0..3-win1` | 叠加层窗口带宽不足，主平面正常 |
| `route-hdmi0/1: failed to get logo,offset` | 无 logo 分区，U-Boot 未写 logo 参数 |
| `drm-cubic-lut@0` 保留内存失败 | 节点 base 为 0，无实际预留 |
