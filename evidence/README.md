# 取证材料说明

本目录保存**文本**取证，来自板端 UART（COM4 @1500000）、`hdc shell` 与构建机。
大文件（`*.tar.gz`、`*.hap`、`*.img`、`.so`、整段构建日志 > 400 KB）不入库，位置见下表。

## 命名约定

- `*.raw.txt`：串口/hdc 的**原样**输出，含内核日志穿插与丢字。
- `*.txt`：过滤掉 `[ 123.456]` 形式的行之后的可读副本。
- `*state*` / `*health*` / `*alive*` 为空文件是**正常**结果：说明探测期间板端未回显。

## 目录

| 目录 / 文件 | 内容 |
| --- | --- |
| `serial-usb-probe-1.txt` | 接入鼠标后的完整 input 设备与 USB 树 |
| `mmi-enumeration.*` | 真实鼠标事件、MMI `No display` 日志 |
| `usb-hid-confirm.*` | usbhid 驱动绑定、MMI 打开 `event7` |
| `display-current-state.*` / `display-state-2.*` | DRM connector / VOP 状态、截图失败、`usb_host` 崩溃 |
| `cursor-screen-ids.*` / `mouse-with-display-mmi.*` | 显示器与鼠标同时在线时的光标挂载 RS 0 / 实际输出 RS 1 |
| `source-review.txt` / `source-screen-id-review.txt` | 构建机源码版本、行号、补丁 diff |
| `build-library.log` | **未入库**，历史 `libwms.z.so` 编译链接日志，仅保留文档结论，不能在本仓库复核完整日志 |
| `cursor-screen-id.patch`、[修正源码与单元测试](../scripts/board/) | 补丁位于本目录；源码副本与测试源在 `scripts/board/` |
| `sceneboard-app-build-20261104.log` | **未入库**（1.8 MB），在 `validation/cursor-20261105/` |
| `sceneboard-boot-stall-*.txt` | 停在 Logo 时的 UART 证据（包数据库、服务、指纹、hilog） |
| `sceneboard-fullflash-*.txt` | 全刷现场记录 |
| `sceneboard-preinstall-r2/` | R2 源码补丁、镜像离线检查 JSON、源文件备份 |
| `sceneboard-system-image/` | R1 镜像检查与签名验证 |
| `sceneboard-linux-rebuild/` | SDK 准备、编译对比、HAP 元数据与哈希 |
| `abandoned-sceneboard-20261105/` | 回退核验（镜像哈希 + 源码恢复） |

## 注意事项

- 板上时钟与工作机时钟可能不一致，时间戳不要跨来源比较先后。
- 串口 1500000 波特率下长输出会丢字，结论只引用清晰且有其他证据支持的行。
- `sceneboard-r2-*` 中多个文件为空，对应 UART 静默期；不要把空文件当采集脚本故障。
- 文本中的主机与用户路径经过脱敏；`.raw.txt` 表示采集原始格式，不保证与未脱敏原文件逐字节相同。
  原始材料缺失项和历史源码缺口见 [复现边界](../docs/11-reproducibility.md)。
