# R2 越过 Logo 后黑屏：待恢复 UART 输出

> 归档说明：以下是历史阶段记录，后续状态以 [SceneBoard 实验汇总](../08-sceneboard-experiment.md) 和 [光标调查](../09-cursor-investigation.md) 为准；本地镜像恢复不代表已完成板上回退。

**后续状态：已按用户要求停止该方向并恢复经典镜像文件。** 用户重新接线并重启后，曾读到 R2 版本、SceneBoard 进程及 WMS/全屏/账号就绪参数均为 true，随后 UART 再次静默。再次连续采集期间用户决定放弃，没有继续定位黑屏原因。详见 [回退记录](SceneBoard-停用与经典版本回退-20261105.md)。下文为先前断线时的采集记录。

日期：2026-11-05。用户报告更新后能够越过 Logo，随后黑屏。尚未通过日志确认实际运行版本、SceneBoard 进程、崩溃原因或显示输出状态。

本轮发现：

- Windows 正常识别 FTDI `USB Serial Port (COM4)`，设备状态 OK。
- COM4、1500000、8N1 可以打开，没有串口占用错误。
- 三次状态/存活探测均没有收到回应，其中一次尝试 Ctrl-C 恢复 shell 提示符。
- 随后进行了 120 秒纯被动监听，没有向板端发送命令，接收到的字符数为 0。

已请用户确认板端 UART 接线，并在监听期间按 Reset。当前尚未收到用户操作结果；不能认定已完成重启采集，也不能据此认定板卡死机或串口硬件损坏。

本轮没有修改镜像、板上参数、应用注册或文件系统。黑屏原因仍未确定，不能把此前预装清单问题直接当成本轮黑屏原因。

采集记录位于 `validation/cursor-20261105/sceneboard-r2-black-screen-state.raw.txt`、`sceneboard-r2-uart-alive.raw.txt`、`sceneboard-r2-uart-interrupt-check.raw.txt` 和 `sceneboard-r2-boot-passive.raw.txt`；最后一个文件为空，与被动采集计数一致。
