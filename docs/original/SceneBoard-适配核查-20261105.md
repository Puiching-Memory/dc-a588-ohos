# SceneBoard 配套适配核查

> 归档说明：以下是历史阶段记录，后续状态以 [SceneBoard 实验汇总](../08-sceneboard-experiment.md) 和 [光标调查](../09-cursor-investigation.md) 为准；本地镜像恢复不代表已完成板上回退。

日期：2026-11-05。核查范围为当前 RK3588 源码树、2026-11-04 的系统构建日志和 SceneBoard 应用构建日志。

**后续验证已完成：Linux SDK 准备修正后，Pad SceneBoard 的 ArkTS 编译、HAP 打包和签名均通过，并已生成启用 SceneBoard 的系统镜像。** 下面保留问题定位过程；最新证据见 [Linux 重编验证结果](SceneBoard-Linux重编验证-20261105.md)，产物见 [镜像及烧录说明](../08-sceneboard-experiment.md)。本轮未烧录或改动板上运行架构。

## 进一步定位：Linux 自动入口跳过 SDK 内部声明准备

已发现一个明确的构建环境问题，不能把大量编译错误直接解释为 SceneBoard 自身或 RK3588 不支持。

修正前的 `applications/standard/window_scene_board/hvigorfile.ts:139`：

```ts
function updateSdkInterface(sdkInfo): void {
  if (process.platform !== 'win32') {
    return;
  }
  // 后续调用 hvigor/update-sdk-interface.js 更新实际 SDK
}
```

构建宿主是 Ubuntu。这个自动入口在 Linux 上必然跳过。另一个入口 `build.sh:158` 提供手动调用，`build.sh:196` 在构建前执行它；因此 Linux 并非完全没有适配路径，但直接运行 Hvigor 时，不能依赖上述 Windows 专用入口。

当前有效 SDK 是 `prebuilts/ohos-sdk/linux/23`，元数据为 API 23、6.1.0.47。SDK 中缺少 `@ohos.sceneSessionManager.d.ts`、`@ohos.screenSessionManager.d.ts` 和 `@ohos.pcService.statusBar.d.ts`。这三个文件实际存在于 SceneBoard 自身的 `staticcommon/basecommon/windowsceneinterfaces/src/main/ets/interfaces/` 中；`hvigor/update-sdk-interface.js:49-117` 明确要求将它们和其他扩展声明复制进 SDK，还包含 effectKit 等声明的覆盖。

对应的 `sceneSessionManager`、`screenSessionManager` NAPI 注册实现在 WindowManager 源码中存在。因此，编译报“找不到模块或声明”不等于板端必然缺少这些运行能力。

把历史日志与当前代码、SDK 内容对照，可以确认当时的有效编译环境没有获得所需内部声明；Linux 自动入口的跳过条件是一个直接解释。尚不能仅凭现有日志断言当时完全未运行手动准备脚本，也可能准备到了其他 SDK 路径。

### 为什么错误数量很多

原始日志中的总计是 1275 条错误；从详细文本可提取出 1274 条 `Error Message`。其中：

| 诊断类别 | 条目数 |
| --- | ---: |
| 找不到模块声明 | 225 |
| 成员不存在或缺少导出 | 413 |
| any / unknown 检查 | 89 |
| 隐式返回类型检查 | 17 |
| 其他诊断 | 530 |

“找不到模块”涉及 11 个名称，其中 `@ohos.sceneSessionManager` 重复 151 次、`@ohos.screenSessionManager` 重复 32 次、`@ohos.pcService.statusBar` 重复 13 次。少数基础模块的类型无法解析，会让大量使用这些类型的文件一起报错；这些数量不能当作独立缺陷数。

本轮已在独立 SDK 副本中完成声明准备，并处理 SDK tsconfig 的尾逗号解析问题。对同一 Pad 目标重新构建后，详细致命错误信息从 1274 条降至 0；225 条致命的模块声明缺失诊断亦降至 0。构建仍有非致命警告，补齐声明后的应用运行情况尚需上板验证，不能将编译通过直接解释为运行时接口全部可用。

## 已找到的实际阻塞

`applications/standard/window_scene_board/.hvigor/outputs/build-logs/build.log` 保留了上次应用源码构建的失败记录：

```text
COMPILE RESULT:FAIL {ERROR:1275 WARN:16993}
BUILD FAILED in 4 min 33 s 749 ms
```

错误示例：

- 原日志第 448 行：找不到 `@ohos.sceneSessionManager` 或对应的类型声明。
- 第 452 行：找不到 `@ohos.pcService.statusBar` 或对应的类型声明。
- 第 472 行：找不到 `@ohos.screenSessionManager` 或对应的类型声明。
- 第 12 行：`getAverageColor` 不存在于 `Promise<ColorPicker> & void` 类型上。
- 另有 ArkTS 的显式类型、返回类型等检查错误。

这些是诊断条目数量，包含接口声明缺失引起的连锁报错，不能解释成 1275 个互相独立的缺陷。它们证明：当时这份 SceneBoard 应用源码与实际使用的 SDK/声明及编译配置尚未对齐。单凭这些日志还不能判定所有缺失模块都不存在于板端运行时，也不能将所有错误归因于同一个 SDK 版本问题。

## 为什么系统构建成功仍不足以证明可用

`/home/<user>/ohos/build-scb.log` 确实记录了 `window_manager_use_sceneboard = true` 和 `rk3588 build success`。但同一日志第 877 行显示，使用的 SceneBoard 来自：

```text
COPY ../../applications/standard/hap/sceneboard/SceneBoard.hap ...
```

对应 `applications/standard/hap/BUILD.gn:326` 为 `ohos_prebuilt_etc("sceneboard_hap")`，只是复制预编译 HAP，不会重新编译该应用。这个成功结果不覆盖上述应用源码构建，也不覆盖预编译包的安装、启动、窗口与系统 UI 运行验收。

此外，该 BUILD.gn 在开关为 true 时会自动加入 SceneBoard 等预编译应用。因此不能只看到产品安装清单中有旧 Launcher/SystemUI，就断言“根本没有配套 SceneBoard”。

## 目前可以给出的结论

前面将继续使用经典架构简单归因为“沿用默认配置”，证据不充分。历史记录表明，配套 SceneBoard 应用源码构建确实存在 SDK 准备阻塞；本轮已通过构建修正解除这一阻塞，但启用框架编译开关和通过应用编译仍不足以完成系统迁移。

这为暂时保留经典架构提供了具体技术依据。但尚未找到当时明确记载回退决策的记录，以及预编译 SceneBoard HAP 的板端故障日志，所以不能声称已经完整还原回退原因，也不能声称已确认预编译 HAP 运行时不兼容。普通业务应用是否兼容新架构亦未在本轮验证。

后续若迁移，应先明确 SceneBoard 应用、系统框架、系统接口 SDK/类型声明及构建工具的对应版本，解决应用构建阻塞，再验证系统 UI、应用启动与双 HDMI 输入显示。

## 已保存的证据

- 应用源码构建原始日志（`sceneboard-app-build-20261104.log`，未入库）
- [构建规则与系统构建摘录](../../evidence/sceneboard-integration-review.txt)
- [SDK 准备路径与缺失声明核查](../../evidence/sceneboard-sdk-preparation-review.txt)
- [Hvigor 构建入口源码副本](../../scripts/sceneboard/SceneBoard-hvigorfile.ts)
- [SDK 声明更新脚本副本](../../scripts/sceneboard/update-sdk-interface.js)
- [错误分类统计](../../evidence/sceneboard-error-statistics.json)

这些文件保存于本地，避免后续 Hvigor 构建覆盖原始错误记录。

