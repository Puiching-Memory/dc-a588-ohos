# DTS 与厂商官方 dts 的系统性比对

- 比对工具：`board-dts/dts_diff.py`
- 原始输出：`board-dts/dts-diff-report.txt`
- 比对对象：我方构建 dtb 反编译结果 vs 厂商官方固件 `dtb-from-official-image/rk3588-evb7-lp4-v10.dts`
- 节点总数：我方 1235，厂商 1017，共有 976

## 一、GPIO 属性：19 项共有属性，全部一致

| 节点 | 属性 | 引脚 |
|---|---|---|
| `/es8388-sound` | `hp-con-gpio` | GPIO1_D2 / HIGH |
| `/es8388-sound` | `spk-con-gpio` | GPIO1_D3 / HIGH |
| `/ethernet@fe1b0000` | `snps,reset-gpio` | GPIO4_B3 / LOW |
| `/hdmi@fde80000` | `enable-gpios` | GPIO4_B1 / HIGH |
| `/hdmi@fdea0000` | `enable-gpios` | GPIO4_B2 / HIGH |
| `/hdmirx-controller@fdee0000` | `hdmirx-det-gpios` | GPIO2_B5 / LOW |
| `/i2c@fead0000/gt1x@14` | `goodix,irq-gpio` | GPIO3_C0 / HIGH |
| `/i2c@fead0000/gt1x@14` | `goodix,rst-gpio` | GPIO3_C1 / HIGH |
| `/leds/work` | `gpios` | GPIO3_B7 / HIGH |
| `/pcie@fe170000` | `reset-gpios` | GPIO1_B4 / HIGH |
| `/pcie@fe180000` | `reset-gpios` | GPIO4_A2 / HIGH |
| `/vcc-3v8-4g` | `gpio` | GPIO3_B4 / LOW |
| `/vcc3v3-pcie` | `gpios` | GPIO2_B4 / HIGH |
| `/vcc5v0-host` | `gpio` | GPIO4_B0 / HIGH |

## 二、status 开关：34 处不一致

### A. 我们少开了（厂商 `okay`，我们 `disabled`）—— 6 处

| 节点 | 用途 |
|---|---|
| `/can@fea50000` | CAN 控制器 |
| `/serial@fd890000` | UART |
| `/serial@feb60000` | UART |
| `/serial@feba0000` | UART |
| `/pwm@febf0020` | PWM（疑似背光或风扇） |
| `/watchdog@feaf0000` | 硬件看门狗（对应已知问题 K1） |

另有 `/hdmiin-sound` 我们完全没有该节点，厂商为 `okay`。

### B. 我们多开了（厂商 `disabled`，我们 `okay`）—— 27 处

| 来源 | 数量 | 节点 |
|---|---|---|
| `#include "rk3588-evb7-v11-imx415.dtsi"` | 11 | `csi2-dphy0`、`csi2-dphy0-hw@fedc0000`、`csi2-dphy1-hw@fedc8000`、`i2c@feab0000`、`rkcif-mipi-lvds2`、`rkcif-mipi-lvds2-sditf`、`rkcif@fdce0000`、`rkisp0-vir0`、`rkisp@fdcb0000`、`iommu@fdcb7f00`、`iommu@fdce0800` |
| EVB7/standard dtsi 默认开启、本板未引出 | 10 | `hdmi@fdea0000`、`hdmi@fdea0000/ports/port@0/endpoint@1`、`hdmi1-sound`、`hdmiphy@fed70000`、`display-subsystem/route/route-hdmi1`、`dp@fde50000`、`dp@fde60000`、`dp@fde50000/.../endpoint@2`、`dp@fde60000/.../endpoint@2`、`dp0-sound` |
| 多媒体/低功耗单元策略差异 | 6 | `av1d@fdc70000`、`avsd-plus@fdb51000`、`dfi@fe060000`、`dmc`、`phy@fedb0000`、`pwm@fd8b0010` |

## 三、单侧独有的 GPIO 节点：13 处

| 侧 | 节点 | 属性 | 引脚 | 说明 |
|---|---|---|---|---|
| 厂商 | `/mark_gpio` | `gpio_pwen` | GPIO3_B4 / LOW | 与我们 `vcc-3v8-4g` 的 `gpio` **同引脚同极性**，命名不同，需核实 GPIO3_B4 实际功能 |
| 厂商 | `/fan-regulator` | `gpio` | GPIO4_A5 / HIGH | 厂商有风扇控制，我们无对应节点；需确认本板是否有风扇 |
| 厂商 | `/i2c@feac0000/mpu_acc@68` | `irq-gpio` | GPIO4_C2 / LOW | 与我们 `icm_acc@68` 同引脚，仅节点名不同，无影响 |
| 我方 | `/vcc-mipidcphy0-regulator` | `gpio` | GPIO1_B2 / HIGH | 摄像头供电，本板无摄像头，应一并禁用 |
| 我方 | `/sdio-pwrseq` | `reset-gpios` | GPIO0_C4 / LOW | SDIO 已禁用，属残留 |
| 我方 | `/vbus5v0-typec` | `gpio` | GPIO3_A6 / HIGH | EVB7 残留，厂商无此节点 |
| 我方 | `/rk-headset` | `headset-gpios` | GPIO1_D5 / LOW | 已 `disabled`，属残留 |
| 我方 | `/i2c@feab0000/imx415@1a` | `pwdn-gpios` | GPIO1_A7 / HIGH | 摄像头，随 imx415 include 一并移除 |
| 我方 | `/i2c@fead0000/hynitron@5a` | `irq-gpios` / `reset-gpios` | GPIO3_C0 / C1 | 触摸，i2c5 已禁用，属残留 |
| 我方 | `/vcc-mipicsi0-regulator` | `gpio` | GPIO1_D2 / HIGH | 已 `disabled`，节点仍在 |
| 我方 | `/vcc-mipicsi1-regulator` | `gpio` | GPIO1_D3 / HIGH | 已 `disabled`，节点仍在 |

## 四、结论

1. **引脚层面已完全对齐**：所有双方都定义的 GPIO 属性（19 项）逐项一致，包括刚修的状态灯 GPIO3_B7。
2. 剩余 34 处差异全部是**节点启用状态**，不是引脚接错。
3. 其中 27 处"多开"是继承 EVB7 默认配置的后果，绝大多数不影响功能，但会让无关驱动去 probe、增加启动时间和日志噪音；imx415 那 11 个节点还会在串口刷 `rkcif_update_sensor_info ... get remote sensor_sd failed`。
4. 6 处"少开"是真实的功能缺失：CAN、3 个 UART、1 个 PWM、硬件看门狗。
5. 待核实：GPIO3_B4 的实际用途（`pwen` vs 4G 供电）、本板是否有风扇。

## 五、用法

```bash
# 在构建机上
python3 dts_diff.py <我方.dts> <厂商.dts>
```

改完 dts 后先跑一遍比对，再决定要不要烧板子。
