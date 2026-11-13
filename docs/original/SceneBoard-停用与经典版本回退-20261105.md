# 停用 SceneBoard，恢复经典 WindowManager

> 归档说明：以下是历史阶段记录，后续状态以 [SceneBoard 实验汇总](../08-sceneboard-experiment.md) 和 [光标调查](../09-cursor-investigation.md) 为准；本地镜像恢复不代表已完成板上回退。

日期：2026-11-05。按用户明确要求，停止 SceneBoard 方向，恢复最后已知能进桌面、HDMI 0 能显示鼠标的经典版本。

## 已完成

- 停止 UART 连续采集进程，不再进行 SceneBoard 调试或构建。
- 将本机 `images/` 中的 Boot、System、Vendor、Sys-prod、Chip-prod 和 Parameter 恢复为实验前备份，其他镜像未替换。
- 对当前 `images/SHA256SUMS.txt` 清单中的全部镜像逐文件校验，均与实验前哈希一致。
- 更新 `images/README-烧录说明.md`，当前交付入口明确为经典版本，回退选择 Boot + System。
- 构建机恢复本轮改动的两个预装 JSON 和 `ohos.para`；恢复前检查内容仍匹配本轮实验修改，未覆盖其他人的后续变化。
- 将构建输出目录 `args.gn` 的 `window_manager_use_sceneboard` 恢复为 `false`，没有再次构建。

没有操作板上烧录、安装、文件系统或重启。板上是否恢复成功，仍需用户烧录后确认。

## 可核验的基线

备份源：`backups/images-before-sceneboard-20261105-112835/`。

| 文件 | SHA256 |
| --- | --- |
| boot.img | `2d0ded4377213019bbf40fce5423c4090316bc066a765612b396d7458f1a74cf` |
| system.img | `62ae221436cd3b36289da08ccc86591e1415e81d4193ec433119b4598388a0e9` |

完整结果：`validation/cursor-20261105/abandoned-sceneboard-20261105/classic-restore-verification.json`。

源码恢复结果：同目录 `source-restore-verification.json`。保留原有经典光标 rsId 修正源码、原 MoveSoft 修改、Linux SDK 准备修正及其他实验前已有工作区变化；这些源文件不等于已打入本次恢复的旧镜像。

## 实验保留情况

R1 构建快照在 `images-sceneboard-20261105/`。R2 镜像在 `validation/cursor-20261105/sceneboard-r2-staging/`，压缩包、补丁和证据在同级目录；回退前的 R2 清单和说明已另存到 `abandoned-sceneboard-20261105/`。

R2 在一次重启约 14 秒时已确认：SceneBoard 进程运行，WMS、全屏窗口及账号就绪参数均为 true，证明预装修正已生效。用户仍观察到黑屏，之后 UART 再次无回应；在连续采集等待期间，用户决定停止该方向。因此黑屏根因未定位，不能把板级缺陷写成已证实结论。

当前回退基线仍保留此前已知问题，包括 HDMI 1 光标显示未完成验收；不因回退而宣布这些问题已修复。
