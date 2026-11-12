# 06 · 板端调试与取证

板上系统：`OpenHarmony-6.1.0.36` / API 23 / `arm64-v8a` / kernel 6.6.101，deviceType `default`，
开发者模式 `true`，网络地址 `192.168.0.12`。

## 1. 串口（最可靠的通路）

| 项 | 值 |
| --- | --- |
| 设备 | COM4 = FTDI `0403:6001` |
| 参数 | **1500000 8N1**，无流控 |
| 用途 | 板载「调试口(ttyS2)」，控制台 `ttyFIQ0`，直接得到 `#` root shell |

- **读串口前先 `hdc kill`**：hdc server 会独占该口。
- 1500000 波特率下长输出会缺字，关键内容（哈希、路径）用短命令分次读。
- 串口会有内核日志穿插，所以取证脚本同时输出 `.raw.txt`（原样）与 `.txt`（过滤掉 `[  123.456]` 行）。

有界取证脚本 `scripts/board/Invoke-BoardProbe.ps1`：

```powershell
.\Invoke-BoardProbe.ps1 -Name display-state -Command "cat /sys/class/drm/*/status" -Seconds 5
.\Invoke-BoardProbe.ps1 -Name mmi-enum -Command "cat /proc/bus/input/devices" -Seconds 4
```

它发 `echo PROBE_BEGIN; <cmd>; echo PROBE_END`，只采样固定秒数。
**超时只结束主机侧采集，不会终止板端命令**——所以只下发有界命令，别发 `dmesg -w`、`logcat` 之类。

## 2. hdc（网络）

```bash
hdc tconn 192.168.0.12:37827
hdc list targets
hdc shell
```

- `hdcd` 只听 TCP **37827**（`persist.hdc.mode.tcp=enable`、`persist.hdc.mode.uart=disable`）。
- `hdc list targets` 里的 `COM4` 是**假目标**，`-t COM4` 必报 `Device not found`。
- `usb_host` 崩溃重启循环会让 hdcd 周期性断开：`hdc kill` 后重新 `tconn`，`Connect failed` 时等 20 s 再试。
- Windows 侧 `hdc.exe` 在
  `...\commandline-tools\sdk\default\openharmony\toolchains\`（命令行工具包内）。
- **不要用 `Test-NetConnection` 判断设备是否在线**：本机 FlClash TUN 会给不可达地址伪造 Established。

## 3. 日志

```bash
hilog -x | grep -i <tag>        # 导出后过滤，-t 是日志类型不是 tag
hilog -r                        # 清缓冲
dmesg | tail -120
```

- `hilog -t` 的参数是 **app/core/init/kmsg** 这类日志类型，按 tag 过滤必须自行 grep。
- `usb_host` 崩溃栈在 `/data/log/faultlog/faultlogger/cppcrash-usb_host-*`。
- 启动日志里 `APPSPAWN sharefs mount /mnt/debugtmp/... errno 2`、`SubInitRun 0`、
  `Invalid dac for 'bootevent.netmanager.ready.'`、`access_tokenid_ioctl: magic fail` 均为噪音。

## 4. 参数与电源

```bash
param get const.product.devicetype
param get persist.multimodalinput.cursor.hwcbounds   # 未设置时返回 errNum 106
power-shell timeout -o 2147483647                    # 不息屏（-r 恢复，默认 300000 ms）
power-shell dump -t                                  # keep screen on
```

- `power-shell timeout` **不持久**，每次重启后要重设；`setmode` 只有 600/601/602/603 四种电源模式。
- 设备曾出现整机复位（`/proc/uptime` 归零、电源计数器归零），间隔约 7 min；不是干净软件重启。

## 5. 截图与显示状态

```bash
snapshot_display -f /data/local/tmp/audit.jpeg
cat /sys/class/drm/card0-HDMI-A-1/status
cat /sys/kernel/debug/dri/0/summary
```

`snapshot_display` 在无有效显示时返回 `GetDisplayById 18446744073709551615 error!`，此时取不到截图，
不能据此判断是软件缺陷——先确认 `/sys/class/drm/*/status` 是否有 `connected`。

## 6. 应用沙箱文件

- 读应用沙箱文件**必须 root**：`/data/app/el2/100/base/<bundle>/haps/entry/files/`。
- OpenHarmony **没有 `run-as`**；`hdc shell -b <bundle>` 只进 `/mnt/debug/100/debug_hap/<bundle>`（空目录）。
- `bm dump` / `hidumper` 在 UART shell 下会被权限检查拒绝，不能把它们的失败当作包未安装的证据；
  包是否存在用只读 SQLite 查询（见 [08-sceneboard-experiment.md](08-sceneboard-experiment.md)）。

## 7. 复位取证

设备会整机复位且 `persist.dfx.shutdown_reason` 为空、pstore 空、无 `/dev/watchdog`。
用 `/data`（重启不丢）留快照：

```bash
hdc shell 'nohup sh -c "while true; do date >> /data/local/tmp/snap.log; dmesg | tail -120 >> /data/local/tmp/snap.log; hilog -x | tail -200 >> /data/local/tmp/snap.log; cat /proc/uptime >> /data/local/tmp/snap.log; sleep 2; done" >/dev/null 2>&1 </dev/null &'
```

**三个 fd 必须都重定向**，否则 hdc 会挂住。
`appspawn` 出现 `hungtask_user ... is kicked` 是用户态 hungtask 看门狗的线索。

## 8. 串口传文件（无 USB、无网络时的兜底）

板端 toybox 缺 `tr` / `awk`（但有 `sqlite3`、`power-shell`），所以传输脚本自己带解码器：

1. `scripts/board/serial_file_receiver.c` 交叉编译成静态程序，gzip 后
   base64 分块经串口写入板端（每块 `AUX_ACK_<offset>` 回执）。
2. 用该解码器把大文件（如 `libwms-cursor-screen-id.so.gz`）按 512 字节块收下，每块 `RAW_ACK <offset>`。
3. 每一步 `gzip -t` + `sha256sum` 校验，校验值写死在脚本里：

```powershell
.\Send-BoardCursorReliable.ps1     # 传接收器 + 传库 + 校验
```

为什么 base64 里要把 `i` 换成 `@`：单引号串经 UART shell 传递时，连续字符可能被解释；
换一个不在 base64 字母表里的字符再 `tr @ i` 还原，可以避开这类破坏。

`Send-BoardCursorLibrary.ps1` 是不带逐块回执的早期版本，长传输会因缓冲溢出失败
（`library-transfer.raw.txt` 里有整段失败的原始记录）；**优先用 `...Reliable.ps1`**。

## 9. 板端时钟与日志时间

板上时钟与工作机时钟可能不一致，取证文本里的时间按原样保留，不要跨来源比较时间戳先后。
