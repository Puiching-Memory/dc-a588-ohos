# 脚本索引

所有脚本来自实际构建与验证环境，路径按**构建机** `/home/<user>/ohos/...` 硬编码。
在别处复用时需要修改这些常量。

## build/

| 文件 | 用途 |
| --- | --- |
| `Dockerfile` | `ohos-6.1-rk:jammy-v3`（ubuntu:22.04 + 全量 OHOS 构建依赖 + 1005 用户） |
| `build-rk3588.sh` | 容器内构建入口（挂载为 `/build.sh`），经典 WindowManager 基线 |
| `sync.sh` | `repo sync` 30 次重试，内置清空失效代理 |
| `lfspull.sh` | 读 `lfs_repos.txt` 逐仓库 `git lfs pull`（`timeout 1200`） |

```bash
docker build -t ohos-6.1-rk:jammy-v3 .
docker run --rm --user 1005:1005 -e HOME=/home/ohos \
  -v ~/ohos/src:/home/ohos/src -v ~/ohos/ccache:/ccache \
  -v ~/ohos/prebuilts_cache:/home/ohos/openharmony_prebuilts \
  -v ~/ohos/build-rk3588.sh:/build.sh:ro -w /home/ohos/src \
  ohos-6.1-rk:jammy-v3 bash /build.sh
```

## dts/

| 文件 | 用途 |
| --- | --- |
| `dts_diff.py` | 比对两份反编译 dts：`status` 差异、GPIO 属性解码差异、单侧独有 GPIO 节点 |
| `pin_audit.py` | 从 `dtc` 反编译结果反推 alias → phandle → `(bank, pin, flags)`，汇总引脚占用 |

```bash
python3 dts_diff.py <我方.dts> <厂商.dts>
python3 pin_audit.py <我方.dts>
```

输入必须是 `dtc -I dtb -O dts` 或 `cpp` 预处理后的**扁平** dts（宏已展开）。

## flash/

| 文件 | 用途 |
| --- | --- |
| `flash-rk3588.bat` | 先 `cd` 进 `rktools\RKDevTool` 再启动 RKDevTool（配置按 CWD 解析） |
| `config.cfg` | RKDevTool v3.37 的分区/地址/文件路径配置（14 行，含强制按地址写） |

## sceneboard/

| 文件 | 用途 |
| --- | --- |
| `run-sceneboard-linux.sh` | 用独立 SDK 副本构建 Pad/Phone/PC SceneBoard HAP，退出时恢复 `local.properties` |
| `build-sceneboard-image.sh` | 宿主侧：校验 HAP 哈希 → 替换预编译 HAP → 起容器构建 → 收集镜像与 `images.sha256` |
| `build-sceneboard-image-container.sh` | 容器内：`window_manager_use_sceneboard=true` 的 `build.sh` |
| `inspect-sceneboard-image.py` | 离线断言：预装目录、能力项、增量版本、文件系统、服务库、HAP 哈希 |
| `compare-boot-fit.py` | 比较两个 `boot.img` 的 FIT 分量哈希（判断是否只换了 System） |
| `compare-scb-builds.py` | 对比两次 SceneBoard 编译的错误/警告统计 |
| `fingerprint-scb-sdk.py` | 记录 SDK 候选改写目标与关键配置指纹（改前/改后一致性） |
| `fix-sceneboard-preinstall.py` | 修 `install_list.json` / `install_list_capability.json` / `ohos.para`，带备份与 `git diff --check` |
| `restore-classic-source-config.py` | 按哈希安全回退预装配置与 `args.gn` 开关 |
| `audit-scb-sdk.cjs` | 用 SDK 自带 TS 解析器检查 `tsconfig.json` 可解析性 |
| `update-sdk-interface.js[.orig]` | 把 SceneBoard 内部 `.d.ts` 复制进 SDK（改前/改后） |
| `SceneBoard-hvigorfile.ts[.orig]` | 构建入口（改前/改后，修 Linux 跳过问题） |

## board/

| 文件 | 用途 |
| --- | --- |
| `Invoke-BoardProbe.ps1` | COM4 有界取证：发 `echo PROBE_BEGIN; cmd; echo PROBE_END`，输出 `.raw.txt` + `.txt` |
| `Send-BoardCursorReliable.ps1` | 串口分块传库：接收器 + 512 字节块 `RAW_ACK` + sha256 校验 |
| `Send-BoardCursorLibrary.ps1` | 早期无回执版本（长传输会失败，仅留档） |
| `serial_file_receiver.c` | 板端接收器，交叉编译静态程序后 gzip+base64 传入 |
| `read-edid.ps1` | 从 Windows 注册表读 EDID 并解析厂商/型号/时序 |
| `Update-LocalSceneBoardImages.ps1` | 把构建机产物拉回本机并覆盖 `images/`（带哈希比对） |
| `input_window_monitor.cpp[.orig]` / `_test.cpp` | 光标 rsId 修正的改后/改前源码与单元测试 |
| `cursor-screen-id.patch` | 上述修正的完整补丁 |

PowerShell 脚本依赖 .NET `System.IO.Ports.SerialPort`，串口固定 `COM4` / 1500000 / 8N1。
