# 11 · 复现边界与源码基线

本仓库是 DC-A588 的适配过程与实验归档。已有脚本、补丁和哈希可以用于检查归档材料，
但没有保存完整的历史源码快照，不能保证从上游当前分支重建出 `images/SHA256SUMS.txt` 对应的镜像。
这一限制与是否开源、是否构建成功、是否通过板上验收分别记录。

## 历史改动清单

| 改动 | 可用材料与应用位置 | 边界 |
| --- | --- | --- |
| 板级 DTS | [归档 DTS](../board-dts/rk3588-evb7-v11-standard.dts) → `kernel/linux/linux-6.6/arch/arm64/boot/dts/rockchip/` | 依赖上游 dtsi 与内核版本，未冻结整棵内核树 |
| heartbeat | `arch/arm64/configs/rk3588_ohos.config` 增加 `CONFIG_LEDS_TRIGGER_HEARTBEAT=y`，见 [板级说明](04-board-dts.md) | 未保存该文件历史完整 diff |
| U-Boot ATF 打包 | `decode_elf.py` 改用 python3，见 [烧录说明](05-flashing.md) | 未冻结 loader、rkbin 及工具链版本 |
| DPI | `foundation/window/window_manager/resources/config/other/display_manager_config.xml` 设置 `<dpi>160</dpi>`，见 [历史交接](original/光标问题-交接简报.md) | 未保存该 XML 历史完整 diff |
| UART root shell | `base/startup/init/services/etc/console.cfg` 的 `start-mode: boot` / `disabled: 0` | 仅为调试历史记录；未归档完整 diff，产品化须关闭 |
| 旧 MoveSoft 实验 | [保留补丁](../evidence/sceneboard-system-image/evidence/retained-movesoft.patch)；项目 `foundation/multimodalinput/input` | 推论已被推翻，有效性未验收，不作为修复默认应用 |
| 经典 WindowManager rsId | [补丁](../scripts/board/cursor-screen-id.patch)；项目 `foundation/window/window_manager` | 库与测试源编译通过，测试二进制未运行，未上板；不等于已包含在回退镜像 |
| SceneBoard Linux SDK 准备 | [补丁](../evidence/sceneboard-linux-rebuild/linux-sdk-preparation.patch)；项目 `applications/standard/window_scene_board` | 应用构建通过，不能证明板端桌面可用 |
| SceneBoard R2 预装与指纹 | [预装补丁](../evidence/sceneboard-preinstall-r2/evidence/preinstall.patch)、[指纹补丁](../evidence/sceneboard-preinstall-r2/evidence/incremental-version.patch) | 已停止该实验；R2 黑屏根因未定位，不用于经典构建 |

可从 [源码取证](../evidence/source-screen-id-review.txt) 核实 WindowManager 当时 HEAD 为
`ac4fbeff04b9560fb004f8ecb834aeccfc66bffd`；这不是整套系统的冻结 manifest。
历史构建机 manifest remote 与文档推荐上游也不同，尚未证明两者提交内容等价。
缺失的历史文件不能通过今天重新导出 manifest 补成当时的事实。

## 后续构建留存

先同步并完成 LFS，再记录真实工作区。`capture-baseline.sh` 只读取源码，输出目录必须不存在：

```bash
# 在本归档仓库根目录执行；输出放在源码树外。
bash scripts/build/capture-baseline.sh "$HOME/ohos/baseline-$(date +%Y%m%d-%H%M%S)"
```

脚本保存 `repo manifest -r`、每个项目 HEAD、状态、相对 HEAD 的已跟踪文件二进制 diff、未跟踪文件名。
它不复制未跟踪文件内容、不采集被忽略文件或子模块内部工作区；这些材料需要另行整理并确认许可与敏感信息。
出现未跟踪源码、子模块修改、缺失依赖时，不应把这份输出称为完整构建基线。

同时保留以下资料，才能解释新构建来自哪些输入：

- 本归档仓库提交、Docker 镜像 ID/digest、实际 Dockerfile、工具链/SDK 版本与构建参数。
- 运行 `scripts/build/build-rk3588.sh` 时的完整日志、退出码、`out/rockchip/args.gn`。
- 实际产物的 SHA256 清单，以及哪些文件已烧录、板上参数和物理显示验收结果。

DTB 哈希只比较设备树。整包版本需要逐镜像校验与源码基线；源码相同也不自动保证字节级可复现。
历史回退记录中的 `boardFlashed=false` 继续有效，本轮归档整理没有执行板上烧录。
