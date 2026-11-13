# 08 · SceneBoard 新桌面架构迁移实验

> **结论先行**：编译、打包、签名、预装清单修复全部做通，R2 镜像能让 SceneBoard 跑起来
> （进程 + WMS/全屏/账号就绪参数均为 true），但随后黑屏、UART 再次静默，根因未定位。
> 按用户要求**停止该方向**，电脑上的 `images/` 已恢复经典 WindowManager 基线；
> **未执行板上回退烧录，回退后的实际启动与 Userdata 兼容性尚未验证。**
> 本页保留完整排障过程，供后续重启该方向时复用。

## 1. 背景

OpenHarmony 6.1 引入 SceneBoard（新桌面/窗口架构），由产品开关控制：

```
window_manager_use_sceneboard = true|false     # args.gn
```

开关为 `true` 时 `foundation/bundlemanager/.../bundle_mgr_service_event_handler.cpp:4340`
的 `HandleSceneBoard()` 会启用 SceneBoard 并**禁用旧 Launcher 和 SystemUI**；
`applications/standard/hap/BUILD.gn:326` 会把预编译 `SceneBoard.hap` 复制进 System。

## 2. 第一阶段：应用源码构建失败（1275 条错误）

`applications/standard/window_scene_board/.hvigor/outputs/build-logs/build.log`：

```
COMPILE RESULT:FAIL {ERROR:1275 WARN:16993}
BUILD FAILED in 4 min 33 s 749 ms
```

直接原因是 SDK 里缺少内部声明：`@ohos.sceneSessionManager`（重复 151 次）、
`@ohos.screenSessionManager`（32 次）、`@ohos.pcService.statusBar`（13 次）。
这三个 `.d.ts` 实际存在于 SceneBoard 自身仓库
`staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/`，
本应由 `hvigor/update-sdk-interface.js` 复制进 SDK。

**根因**：`hvigorfile.ts` 的自动入口写死了 Windows 判断：

```ts
function updateSdkInterface(sdkInfo): void {
  if (process.platform !== 'win32') {
    return;              // 构建宿主是 Ubuntu，Linux 上必然跳过
  }
  ...
}
```

直接跑 Hvigor 时不会做 SDK 声明准备；`build.sh:158/196` 提供的手动入口只在经 `build.sh` 构建时才走。
1275 条错误里绝大部分是这几个基础模块解析失败引起的连锁报错，不能当作独立缺陷数。

错误分类（详细文本可提取 1274 条 `Error Message`）：
找不到模块声明 225、成员不存在/缺少导出 413、any/unknown 检查 89、隐式返回类型 17、其他 530。

## 3. 第二阶段：Linux SDK 准备修正

修改两个构建文件（**未改任何业务源码，也没有关闭类型检查**）：

1. `applications/standard/window_scene_board/hvigorfile.ts`
   - SDK 声明准备在 Linux 上也执行；
   - 用当前 Node 可执行文件和独立参数启动脚本，兼容路径空格；
   - 准备失败终止构建。
2. `applications/standard/window_scene_board/hvigor/update-sdk-interface.js`
   - 校验传入的是 SDK 版本目录；
   - 实际创建目标目录，把复制/解析失败向外传播；
   - 用同一 SDK 的 TypeScript 解析器读 `tsconfig.json`（原生严格 JSON 解析会被尾逗号/注释打断）；
   - 核对核心内部声明内容；相同文件不重复写，保留增量缓存。

隔离策略：复制出独立 SDK `/home/<user>/ohos/validation/sceneboard-linux-20261105/sdk/23`
（不用硬链接，避免污染共享 SDK），构建入口 `scripts/sceneboard/run-sceneboard-linux.sh` 在
`trap ... EXIT` 里恢复 `local.properties`。

结果：

| 阶段 | 结果 |
| --- | --- |
| Linux SDK 准备 | 成功，核心声明与仓库原文件逐字节一致 |
| 首次完整 ArkTS 编译 | 成功，`CompileArkTS` 6 分 30 秒，**详细致命错误 0 条** |
| 首次 HAP 打包 | 失败：宿主无 `java`，`spawn java ENOENT` |
| 补齐 Java 8 后 | 成功，复用编译缓存，14.6 s 完成打包/检查/签名 |

Java 从已有 `ohos-6.1-rk:jammy-v3` 镜像里复制 OpenJDK `1.8.0_504` 到验证目录，不装到主机系统目录。
（`app_packing_tool.jar` 字节码 major 52，`hap-sign-tool.jar` major 51/52，都需要 Java 8。）

产物：`pad_sceneboard-default-signed.hap`，118,993,418 字节，
包名 `com.ohos.sceneboard`，模块 `pad_sceneboard`，编译 SDK `6.1.0.47`，最低/目标 API 20，
SHA256 `7b21b08807499486d7ff0b711e95f2d6d8d33eeb2a23450bd1b0ed396f97163f`。
（HAP 体积太大，不入库；哈希用于校验构建产物。）

仍存在的非致命警告：资源、类型声明、外部模块 `Cannot find module` 等，不能称为零警告。
`libhgmnapi.z.so` 存在于系统产物；`fusionsearchclient` 未在系统产物中找到，部署时需核实。

## 4. 第三阶段：构建启用 SceneBoard 的系统镜像（R1）

`scripts/sceneboard/build-sceneboard-image.sh`：

1. 校验新 HAP 的 SHA256；
2. 把新 HAP 覆盖到 `applications/standard/hap/sceneboard/SceneBoard.hap`（`trap` 里按哈希判定后恢复原文件）；
3. `docker run` 执行 `build-sceneboard-image-container.sh`，GN 参数加 `window_manager_use_sceneboard=true`；
4. 收集 `system.img boot.img vendor.img sys_prod.img chip_prod.img parameter.txt` 并生成 `images.sha256`。

只烧 System 验证（`0x00029000`）。

## 5. 第四阶段：板上停在 Logo

UART 只读取证（`evidence/sceneboard-boot-stall-*`）：

| 观察 | 结论 |
| --- | --- |
| `/etc/sceneboard.config` = `ENABLED` | 开关生效 |
| `/system/app/SceneBoard/SceneBoard.hap` SHA256 = `7b21b088…` | 镜像里的 HAP 是本次构建产物 |
| RenderService / Foundation / 账号服务均在运行，Foundation 映射了 `libscreen_session_manager.z.so` | 框架侧就绪 |
| 无 SceneBoard 进程 | 应用没被拉起 |
| 只读 SQLite：`installed_bundle` 中 `com.ohos.sceneboard` 记录数 **0** | 包从来没被安装 |
| `bundle_user_info.json`：`com.ohos.launcher_100`、`com.ohos.systemui_0` 均 `enabled: false`，`setEnabledCaller: bms` | 旧桌面被架构开关禁用 |
| AMS 每 ~200 ms 输出 `waiting query highest priority ability info completed` | 找不到可启动桌面 |
| `bootevent.wms.ready / wms.fullscreen.ready / account.ready` = false | 桌面链路未就绪 |

`bm dump` / `hidumper` 在 UART shell 下被权限拒绝，不能作为「包未安装」证据；
该结论来自 SQLite 只读查询。

相关源码：
`bundle_mgr_service_event_handler.cpp:241`（优先加载持久化包数据库）、`:411`（仅 `IsSystemUpgrade()` 时
进入 `OnBundleRebootStart()`）、`:3234/:3245`（升级条件：测试参数或产品指纹不同）、
`ability_manager_service.cpp:7862`（启动时循环查询最高优先级桌面 Ability，无重试退出条件）。

产品指纹：

```
OpenHarmony 6.1.0.36/default/default/Rockchip OpenHarmony 6.1 LTS/default/default
```

首次没改指纹，确实跳过了「保留 Userdata 的升级扫描」；但**全刷也没有解决**，因为真正缺的是预装清单。

## 6. 第五阶段：预装清单修复（R2）

BMS 编译参数包含 `USE_PRE_BUNDLE_PROFILE`，按清单安装。产品清单
`/system/etc/app/install_list.json` 里**没有** `/system/app/SceneBoard`，
所以 HAP 虽然被复制进 System，首次启动也不会安装它。

`scripts/sceneboard/fix-sceneboard-preinstall.py` 做三处修改（先备份，改完跑定向 `git diff --check`）：

1. `vendor/rockchip/rk3588/preinstall-config/install_list.json`
   增加 `{"app_dir": "/system/app/SceneBoard", "removable": false}`
2. 同目录 `install_list_capability.json` 增加：

```json
{
  "bundleName": "com.ohos.sceneboard",
  "app_signature": ["8E93863FC32EE238060BF69A9B37E2608FFFB21F93C862DD511CBAC9F30024B5"],
  "allowAppUsePrivilegeExtension": true,
  "allowAbilityPriorityQueried": true,
  "allowAppRunWhenDeviceFirstLocked": true
}
```

   签名指纹由发布 profile 的 `distribution-certificate` 做 DER→SHA256 得出，脚本里 `assert` 校验
   `bundle-name` 与 `apl=system_core`；没有复制 SystemUI 的 singleton 配置。
   `bundle_install_checker.cpp` 在缺少 `allowAbilityPriorityQueried` 时会把桌面扩展的 priority 清零，
   所以只加目录不够。
3. `base/startup/init/services/etc/param/ohos.para`：
   `const.product.incremental.version=sceneboard-preinstall-20261105-r2`，用于在保留数据的情况下
   触发系统应用升级扫描。

R2 镜像：整系统重编 8 分 1 秒，System SHA256 `b3f5382450d20a6b9e7741a68bbb8f6f7e7e56148c70a12aafb980744d8ad55c`；
Boot 与 R1 逐字节一致（用 `compare-boot-fit.py` 比对 FIT 内各分量）。
`inspect-sceneboard-image.py` 做离线断言：预装目录、签名限定的能力项、增量版本、文件系统、服务库与 HAP 哈希。
只烧 System，保留 Userdata。

## 7. 第六阶段：越过 Logo 后黑屏

一次重启约 14 s 时确认：**SceneBoard 进程已运行，WMS、全屏窗口、账号就绪参数均为 true** ——
说明预装修正生效。但用户看到黑屏，随后 UART 再次静默（三次探测无回应、120 s 被动监听收到 0 字符）。
重新接线重启后情况相同。

黑屏根因**未定位**。按要求停止该方向。

## 8. 回退

`scripts/sceneboard/restore-classic-source-config.py`：

- 按 `source-fix.json` 里记录的哈希逐文件恢复两个预装 JSON 与 `ohos.para`
  （恢复前校验当前内容仍是本轮实验改动，避免覆盖他人后续修改）；
- 把 `out/rockchip/args.gn` 的 `window_manager_use_sceneboard` 改回 `false`（不重新构建）；
- 保留 Linux SDK 准备修正、光标 rsId 修正等其他工作区改动。

镜像回退：从 `backups/images-before-sceneboard-20261105-112835/` 恢复
Boot `2d0ded43…` / System `62ae2214…` 等 6 个文件，逐文件校验哈希，见
`evidence/abandoned-sceneboard-20261105/classic-restore-verification.json`。

该记录明确 `boardFlashed=false`，只证明电脑上的文件恢复与哈希校验通过，
不代表开发板已经运行回退版本。

## 9. 证据索引

| 内容 | 位置 |
| --- | --- |
| 应用源码构建原始日志（1.8 MB） | 工作机 `validation/cursor-20261105/sceneboard-app-build-20261104.log`（未入库） |
| 错误分类统计 | `evidence/sceneboard-error-statistics.json` |
| SDK 准备核查与集成核查 | `evidence/sceneboard-sdk-preparation-review.txt`、`sceneboard-integration-review.txt` |
| 构建入口与声明更新脚本（改前/改后） | `scripts/sceneboard/SceneBoard-hvigorfile.ts[.orig]`、`update-sdk-interface.js[.orig]` |
| 停止 Logo 的 UART 原始记录 | `evidence/sceneboard-boot-stall-*.raw.txt` 与 `.txt` |
| 全刷现场记录 | `evidence/sceneboard-fullflash-*.txt` |
| R2 离线检查 | `evidence/sceneboard-preinstall-r2/evidence/image-inspection.json` |
| R2 源码补丁 | `evidence/sceneboard-preinstall-r2/evidence/preinstall.patch`、`incremental-version.patch` |
| 回退核验 | `evidence/abandoned-sceneboard-20261105/` |

## 10. 结论与后续建议

1. **不要**把「预编译 SceneBoard HAP 复制进 System」等同于「SceneBoard 已安装」——
   清单模式下必须在 `install_list.json` 里显式声明。
2. 启用 SceneBoard 时旧 Launcher/SystemUI 被禁用，**任何安装失败都会直接表现为停在 Logo**，
   所以迁移前必须先验证 `installed_bundle` 里有 `com.ohos.sceneboard`。
3. 黑屏问题需要新的抓手：R2 已能进入桌面进程，下一步应抓 SceneBoard 的 `hilog`、
   RS 合成日志与 `snapshot_display`，区分「无输出」与「输出黑帧」。
4. Linux 上的 SDK 声明准备修正是**通用**的，后续任何 `window_scene_board` 构建都应带上，
   不能依赖 `build.sh` 的 Windows 入口。
