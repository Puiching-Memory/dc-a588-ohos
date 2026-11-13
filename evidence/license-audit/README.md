# 许可核对证据

本目录记录 2026-11-13 对实际分发材料的来源和适用声明核对。方法与结论见
[许可核对记录](../../docs/13-license-audit.md)。

- `audit.json`：固定源码提交与 tree、路径列表哈希、源文件 blob/SHA256、许可副本、改前源码和补丁检查。
- `upstream/vendor_hihope/`：官方固定提交的两份配置及一个不适用于本次配置的蓝牙 NOTICE，保留原始字节。
- `vendor-hihope-to-rockchip-*.diff`：官方对照与历史 Rockchip 配置的完整文本差异，仅归一化 CRLF/LF。
- 上游许可正文存于 [LICENSES/upstream/](../../LICENSES/upstream/)，复用同一字节内容的原文不重复保存。

`audit.json` 的 `artifacts` 中 SHA256 按原始字节计算，`originalCopyChecks` 则明确按 LF 归一化计算。
`.gitattributes` 对上游原始副本禁用换行转换，以免 Git 在 Windows 上改写其校验内容。
这些证据只针对当前归档分发范围，不是全 SDK、整套固件或板上验收报告。
