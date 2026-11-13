# 13 · 已分发材料的许可核对（2026-11-13）

**结论：本仓库作为实验适配归档的源码许可与适用声明核对已完成，可以按 README 披露的边界公开。**
这项结论针对仓库实际收录的源码副本、节选、补丁、配置和文档，不覆盖未分发的整套 OpenHarmony
源码树、SDK、固件镜像、HAP、第三方工具或其运行时依赖，也不代替构建及实机验收。

## 核对方法与版本

通过 SSH 只读访问原构建机，从 Git 对象读取 `git show <commit>:<file>` 与递归
`git ls-tree -r --name-only <commit>`。不读取当前默认分支来替代历史版本，也不把网页 404 当成没有 NOTICE 的证据。
下表八个提交的完整文件树已检查，未发现文件名以 `NOTICE` 开头的文件（不区分大小写）。

| 组件 | 核对提交 | 本仓库实际收录内容 | 适用许可与证据 |
| --- | --- | --- | --- |
| `foundation/window/window_manager` | `ac4fbeff04b9560fb004f8ecb834aeccfc66bffd` | 光标修正的源码、改前副本、测试、补丁与节选 | Apache-2.0；[原 LICENSE](../LICENSES/upstream/openharmony-common.LICENSE.txt) |
| `applications/standard/window_scene_board` | `71f0c83f97da70f8c1f5ec4e30257af7767ef9bd` | Hvigor、SDK 声明更新脚本、原构建入口及补丁 | Apache-2.0；[LICENSE](../LICENSES/upstream/window_scene_board.LICENSE.txt)、[README.OpenSource](../LICENSES/upstream/window_scene_board.README.OpenSource.json)；另原样保留 [Bodymovin MIT COPYING](../LICENSES/upstream/window_scene_board.COPYING.txt) |
| `foundation/multimodalinput/input` | `5c0f1d08cb7d563778bdba222a7576d9410c0198` | MoveSoft 实验补丁与源码节选 | Apache-2.0；其 LICENSE 字节哈希与 WindowManager 相同，见 [audit.json](../evidence/license-audit/audit.json) |
| `foundation/graphic/graphic_2d` | `25e62af3936f1e29610b0b1de9a5b0adfa6bf356` | RS 光标消费链路的源码节选 | Apache-2.0；其 LICENSE 字节哈希与 WindowManager 相同 |
| `applications/standard/hap` | `f6fda72a768cbdde4bb0298626de2478ea99a83a` | `BUILD.gn` 的构建规则节选 | Apache-2.0；其 LICENSE 字节哈希与 SceneBoard 相同 |
| `base/startup/init` | `8f53a20bddadf5d132889693a5054794a9b8a7c6` | `ohos.para` 增量版本补丁 | Apache-2.0；[原 LICENSE](../LICENSES/upstream/startup_init.LICENSE.txt) |
| `kernel/linux/linux-6.6` | `a36241080fd0dd94fb668924795a0dee9dfdef8e` | 板级 DTS，未收录内核实现或依赖 dtsi 的完整源码 | 基础 DTS 文件头明确 `(GPL-2.0+ OR MIT)`；保留版权与双许可，本仓库选择 MIT 分支，[内核 MIT 许可规则原文](../LICENSES/upstream/linux-6.6.MIT.txt) |
| `vendor/rockchip` | `ef028e3e1139b2a98862ce5c97ec11b2715cc79e` | 两个预装 JSON 的改前副本与 R2 配置增量 | 该提交没有根 LICENSE；按下节核对实际分发配置的 Apache-2.0 来源，不推定整个产品仓都采用此许可 |

保留材料：[NOTICE](../NOTICE)、[原始许可副本](../LICENSES/upstream/)、[机器可读证据](../evidence/license-audit/audit.json)。
证据含各组件 commit/tree、递归路径列表哈希、源文件 Git blob 与 SHA256，未包含构建机地址、用户名或凭据。
这些固定提交是许可核对的证据，不构成整套系统的冻结 manifest。

## Rockchip 预装配置的来源比对

没有把无根 LICENSE 的整个产品仓重新标为 Apache-2.0。核对对象限定为仓库内实际保存的两份 JSON：

- `rk3588/preinstall-config/install_list.json`
- `rk3588/preinstall-config/install_list_capability.json`

从 OpenHarmony 官方 `vendor_hihope` 取固定对照提交
[`4f004ef41b5312630e14ab39af52fe9b2b9afd16`](https://github.com/openharmony/vendor_hihope/tree/4f004ef41b5312630e14ab39af52fe9b2b9afd16)，
核对其 [Apache-2.0 LICENSE](../LICENSES/upstream/vendor_hihope.LICENSE.txt) 与
`rk3568/preinstall-config/` 下的同名文件。对照文件已在
[upstream/vendor_hihope/](../evidence/license-audit/upstream/vendor_hihope/) 保留原始字节和来源 blob，
该提交仅用于来源对照，不声称它就是历史构建输入。

归一化 CRLF/LF 后，差异严格限定为：

| 文件 | Rockchip 配置相对官方对照的差异 | 完整比对 |
| --- | --- | --- |
| `install_list.json` | 增加 `ohos.samples.screenrecorder` 与 `com.ohos.browser` 两条预装路径记录 | [diff](../evidence/license-audit/vendor-hihope-to-rockchip-install_list.json.diff) |
| `install_list_capability.json` | 替换 `com.ohos.backgroundtaskmgr.resources` 的一处公开证书 SHA256 指纹 | [diff](../evidence/license-audit/vendor-hihope-to-rockchip-install_list_capability.json.diff) |

其余内容与对照源一致；这些差异是应用标识、布尔开关及证书指纹的运行配置数据，没有引入另一份实现代码。
本项目 R2 新增的 SceneBoard 目录与权限项是本项目修改，保留原配置主体的许可与来源。
因此本次配置来源核对只覆盖这两份配置及相关增量，不授予 Rockchip 产品仓、软件包或签名密钥的再分发权。

官方对照仓的完整树另有 `dayu210/bluetooth/NOTICE`。已读取确认它声明的是 Broadcom 蓝牙实现，
不涉及这两个 `rk3568/preinstall-config/` 文件；本仓库没有收录该蓝牙实现。
仍将 [NOTICE 原文](../evidence/license-audit/upstream/vendor_hihope/dayu210-bluetooth-NOTICE.txt) 作为核对证据留存，
没有将其误用为所有预装应用的授权。

## 原文件、补丁与声明保留

6 份改前副本与原构建机相应 Git 对象在只归一化 CRLF/LF 后一致；
5 组补丁已在临时目录对对应固定提交的文件应用，WindowManager 与 SceneBoard 的输出还与归档源码副本比对一致
（不计本项目后来添加的修改声明行）。具体路径与结果见 `audit.json` 的 `originalCopyChecks`、`patchChecks`。
后续数据生成和检查没有修改原构建机源码。

SceneBoard 的根 `COPYING` 是 Bodymovin MIT 文本；为完整保留所取源包的声明，
本次将其原样留存并在 NOTICE 中注明，各个构建脚本仍遵循自身的 Apache-2.0 头部。
实际节选涉及的 Huawei 版权年份也已补入 NOTICE，DTS 保留 Rockchip 版权与原 SPDX 声明。

公开的是适配实验归档；历史镜像复现、板上回退和光标修正验收等限制继续见
[复现边界](11-reproducibility.md) 与 [整改记录](12-publication-review.md)。
