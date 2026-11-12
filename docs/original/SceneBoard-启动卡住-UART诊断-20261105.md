# SceneBoard 启动停在 Logo：UART 诊断

日期：2026-11-05。通过 COM4、1500000 波特率进行只读检查，没有重启、安装应用、修改参数或清理数据。

## 结论

**后续全刷实验已修正最初归因：旧 Userdata 不是充分原因，全刷也没有解决问题。** 全刷后账号数据已重新生成，SceneBoard 仍未注册。已查明 BMS 编译时启用了 `USE_PRE_BUNDLE_PROFILE`，但产品的 `/system/etc/app/install_list.json` 没有 `/system/app/SceneBoard`，导致首次安装也跳过 SceneBoard。清单、相关桌面能力配置及增量版本标识已在 [R2 镜像](SceneBoard-预装清单修复-20261105.md) 中修正并通过离线检查，已直接覆盖本机 `images/`；R2 尚未上板。

两次现场共同的直接阻塞是：新 System 已生效，包数据库没有注册 `com.ohos.sceneboard`；BMS 根据开关禁用了旧 Launcher 和 SystemUI，AMS 因而持续查询不到可启动的桌面，停在启动 Logo。

首轮未改变产品指纹，确实也跳过了保留 Userdata 时的升级扫描。但即使触发扫描，缺失的预装清单项仍必须修复。此前仅根据指纹判断全刷可以解决，结论不完整。

## 板上证据

- `/etc/sceneboard.config` 为 `ENABLED`。
- `/system/app/SceneBoard/SceneBoard.hap` SHA256 为 `7b21b08807499486d7ff0b711e95f2d6d8d33eeb2a23450bd1b0ed396f97163f`，与本次源码构建一致。
- RenderService、Foundation、账号服务都已运行；Foundation 映射了 `libscreen_session_manager.z.so`；没有 SceneBoard 进程。
- 只读 SQLite 查询 `installed_bundle` 中 `com.ohos.sceneboard` 的记录数为 **0**；旧 Launcher、SystemUI 的记录仍存在。
- `bundle_user_info.json` 中，`com.ohos.launcher_100` 与 `com.ohos.systemui_0` 均为 `enabled: false`，`setEnabledCaller: bms`。
- AMS 每约 200 ms 输出 `waiting query highest priority ability info completed`；BMS 同时输出旧桌面被禁用、无法找到目标 Ability 的信息。
- `bootevent.wms.ready=false`、`bootevent.wms.fullscreen.ready=false`、`bootevent.account.ready=false`；核心渲染和应用框架就绪参数已为 true。

数据库保存的指纹与当前产品参数拼接结果一致：

```text
OpenHarmony 6.1.0.36/default/default/Rockchip OpenHarmony 6.1 LTS/default/default
```

`bm dump` 和 `hidumper` 在当前 UART shell 下被权限检查拒绝，不能把它们的失败当作包未安装的证据。包缺失结论来自 SQLite 的只读查询。

## 对应源码

构建机源码前缀：`/home/<user>/ohos/src/`。

- `foundation/bundlemanager/bundle_framework/services/bundlemgr/src/bundle_mgr_service_event_handler.cpp:241` 附近：优先加载持久化包数据库。
- 同文件 `:411`：只有 `IsSystemUpgrade()` 成立时进入 `OnBundleRebootStart()`，进行系统应用升级处理。
- 同文件 `:3234`、`:3245`：升级条件为测试升级参数或新旧产品指纹不同；指纹参数列表在 `:94`。
- 同文件 `:4340`：`HandleSceneBoard()` 根据开关启用 SceneBoard、禁用旧 Launcher 和 SystemUI。
- `foundation/ability/ability_runtime/services/abilitymgr/src/ability_manager_service.cpp:7862` 附近：启动时循环查询最高优先级桌面 Ability，启动场景没有普通切换账号时的有限重试退出条件。

## 后续修复与验证

需要先修正产品预装清单及 SceneBoard 的能力配置，再通过可区分的增量版本指纹触发保留数据时的升级扫描。随后验证 SceneBoard 进程、窗口服务就绪参数及桌面显示。

本轮未执行上述修复。SceneBoard 的业务运行、外部模块警告、双 HDMI 和鼠标显示仍未得到验证。

UART 原始记录及提取记录位于 `validation/cursor-20261105/sceneboard-boot-stall-*.raw.txt` 和对应 `.txt`。板上时钟与工作机时钟可能不一致，日志时间按原样保留。
