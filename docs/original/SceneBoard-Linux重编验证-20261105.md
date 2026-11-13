# SceneBoard Linux SDK 准备与重编结果

> 归档说明：以下是历史阶段记录，后续状态以 [SceneBoard 实验汇总](../08-sceneboard-experiment.md) 和 [光标调查](../09-cursor-investigation.md) 为准；本地镜像恢复不代表已完成板上回退。

**当前已停止采用 SceneBoard，`images/` 已恢复经典 WindowManager 基线。** 下文为实验历史，不是当前烧录指引。见 [经典版本回退](SceneBoard-停用与经典版本回退-20261105.md)。

**板上后续状态：**用户局部更新及全量刷写后均停在启动 Logo。UART 与源码核对确认：BMS 使用预装清单模式，而产品清单漏了 SceneBoard，因此即使初始化 Userdata 也不会安装它；旧 Launcher/SystemUI 又被架构开关禁用。此前仅归因旧数据、指纹未变不完整。详见 [UART 启动诊断](SceneBoard-启动卡住-UART诊断-20261105.md)。[R2 修正版](SceneBoard-预装清单修复-20261105.md) 已完成重编、离线检查及原 `images/` 目录覆盖，本次只需更新 System，尚未在板上启动验证。

日期：2026-11-05。结果：**SDK 准备、Pad SceneBoard 的 ArkTS 编译、HAP 打包检查及签名均已通过；随后已构建启用 SceneBoard 的整套系统镜像，并完成离线检查**。未执行烧录，板上架构和运行状态未在本轮改动。

系统镜像交付：[images/README-烧录说明.md](../08-sceneboard-experiment.md)。本次更新使用该目录的 Boot + System，新产物已按用户要求直接覆盖到 `images/`；原文件备份位于 `backups/images-before-sceneboard-20261105-112835/`。

## 验证结果

| 阶段 | 结果 |
| --- | --- |
| 11 月 4 日原应用源码构建 | 失败，日志汇总 1275 条错误；详细错误信息 1274 条 |
| Linux SDK 准备 | 成功；核心内部声明与仓库原文件逐字节一致 |
| 本轮首次完整 ArkTS 编译 | 成功，`CompileArkTS` 用时 6 分 30 秒；详细致命错误信息为 0 |
| 首次 HAP 打包 | 因宿主无 `java` 失败，`spawn java ENOENT` |
| 补齐 Java 后继续构建 | 成功；复用上述编译缓存，14.623 秒完成打包、检查、签名 |
| 产物检查 | 签名 HAP 已生成；ZIP CRC 检查及下载后 SHA256 比对通过 |
| 原 SDK 与本地配置 | 脚本候选改写目标及关键配置的指纹前后一致；`local.properties` 已恢复原内容 |

14.623 秒是补齐 Java 后的增量构建时间，不能作为首次完整源码编译耗时。

## 修正内容

实际修改了构建机源码仓的两个文件：

1. `applications/standard/window_scene_board/hvigorfile.ts`
   - SDK 声明准备也在 Linux 上执行。
   - 使用当前 Node 可执行文件和独立参数启动脚本，兼容路径中的空格。
   - 准备失败时终止构建。
2. `applications/standard/window_scene_board/hvigor/update-sdk-interface.js`
   - 校验传入的是 SDK 版本目录。
   - 创建实际需要的目标目录，传播实际复制、解析失败。
   - 用同一 SDK 的 TypeScript 解析器读取允许尾逗号和注释的 `tsconfig.json`；原来的严格 JSON 解析会失败。
   - 核对核心内部声明的内容；相同文件不重复写入，以保留增量缓存。
   - 保留上游对缺省可选源文件的跳过逻辑。

没有修改 SceneBoard 应用的业务源码，也没有通过关闭类型检查绕过编译。验证脚本同时确认：无效 SDK 路径会被拒绝，重复准备不会重复追加 DynamicComponent 配置。

## 构建环境与隔离

- 构建机：`<BUILD_HOST>:<SSH_PORT>`，Ubuntu。
- SDK：API 23 / `6.1.0.47`。
- 独立 SDK：`/home/<user>/ohos/validation/sceneboard-linux-20261105/sdk/23`，由原 SDK 复制，未使用共享硬链接。
- Java：从已有 `ohos-6.1-rk:jammy-v3` 构建镜像复制至验证目录的 OpenJDK `1.8.0_504`，未安装到主机系统目录。
- SDK 的 `app_packing_tool.jar` 等字节码目标为 Java 8（major 52）；`hap-sign-tool.jar` 中的类为 major 51/52。本轮已实际完成打包和签名。
- 源码版本：`window_scene_board` 基线 `71f0c83f`，加本轮两个构建文件的修改。
- 目标：`pad_sceneboard@default`，产品 `default`，`buildMode=release`。

复现入口（在构建机上运行）：

```sh
bash /home/<user>/ohos/validation/sceneboard-linux-20261105/run-sceneboard-linux.sh \
  pad_sceneboard pad-repeat
```

脚本临时把项目指向独立 SDK，并在退出时恢复 `local.properties`。后续独立构建仍应使用这个入口，避免让应用 SDK 准备操作作用于共享的原 SDK。

## 产物

pad_sceneboard-default-signed.hap（`pad_sceneboard-default-signed.hap`，未入库）

- 大小：118,993,418 字节。
- 包名：`com.ohos.sceneboard`。
- 模块：`pad_sceneboard`。
- 编译 SDK：`6.1.0.47`，最低及目标 API 均为 20。
- SHA256：`7b21b08807499486d7ff0b711e95f2d6d8d33eeb2a23450bd1b0ed396f97163f`。

这是本次 Pad 应用构建的验证产物，已打入上述 SceneBoard System 镜像并核对哈希，尚未进行板上部署验收。

## 证据和边界

证据目录：[sceneboard-linux-rebuild](../../evidence/sceneboard-linux-rebuild/)。

- `pad_sceneboard.log`：SDK 准备、完整 ArkTS 编译成功，随后因缺 Java 停止。
- `pad_sceneboard-java8.log`：增量复用编译缓存，打包、检查、签名与整体构建成功。
- `compile-comparison.json`：历史错误与本轮编译诊断对比；错误和警告分开统计。
- `linux-sdk-preparation.patch`：完整修正补丁。
- `sdk-core-interface-sha256.txt`：核心声明内容一致性证据。
- `original-sdk-fingerprint-before.json` / `after.json`：原 SDK 候选改写目标及关键配置的指纹。
- `java-version.txt`、`pad-hap-metadata.json`、`pad-hap.sha256`：工具版本和产物信息。

构建仍有资源、类型声明及外部模块警告，包括一些非致命的 `Cannot find module` 提示，不能称为零警告。`libhgmnapi.z.so` 在现有系统产物中存在；`fusionsearchclient` 未在本轮扫描的系统产物中找到，后续部署时需要进一步核实其实际解析和功能路径。

尚未验证 Phone/PC 目标、安装启动、系统 UI、双 HDMI、多窗口或长期稳定性。此次结果确认了 Linux SDK 准备缺口及其构建修正，不能代替 SceneBoard 整体上板验收，也不能单独还原此前回退的全部原因。

