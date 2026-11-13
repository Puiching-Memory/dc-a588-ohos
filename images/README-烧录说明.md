# RK3588 经典 WindowManager 回退版本

当前交付：已按用户要求停止采用 SceneBoard，将本 `images/` 目录恢复到此前能进入桌面、HDMI 0 可显示鼠标的经典 WindowManager 镜像。

文件来自 `../backups/images-before-sceneboard-20261105-112835/`。清单中的全部镜像已逐文件核对 SHA256，与实验前版本一致。

## 烧录文件

烧录工具继续使用本目录的原文件路径，回退需选择配套的 Boot 和 System：

| 勾选 | 分区 | 起始地址（扇区） | 文件 |
| --- | --- | --- | --- |
| 是 | Boot | `0x00006000` | `boot.img` |
| 是 | System | `0x00029000` | `system.img` |

本轮仅恢复电脑上的文件，没有执行板上烧录。回退后的实际启动和保留当前 Userdata 的兼容情况尚未验证。Userdata 若另行选择刷写，会清除现有用户数据。

## 关键哈希

- Boot：`2d0ded4377213019bbf40fce5423c4090316bc066a765612b396d7458f1a74cf`
- System：`62ae221436cd3b36289da08ccc86591e1415e81d4193ec433119b4598388a0e9`

完整校验值见本目录 `SHA256SUMS.txt`。

## 留档与已知边界

SceneBoard R1/R2 镜像、源码补丁、检查报告和 UART 记录均已留档，停止继续验证该方向。R2 的进程启动和服务就绪曾得到确认，黑屏根因未定位，尚不能断言是板级缺陷。

本次回退恢复的是此前可用基线；不代表 HDMI 1 光标问题或其他历史缺陷已解决。

详细记录：[停用 SceneBoard 与经典版本回退](../docs/original/SceneBoard-停用与经典版本回退-20261105.md)。
