# RK3588 SceneBoard R2 预装清单修正版

日期：2026-11-05。增量版本：`sceneboard-preinstall-20261105-r2`。

## 这次只更新 System

新文件已直接覆盖到本 `images/` 目录。烧录工具继续使用原文件路径：

```text
D:\Users\<user>\Downloads\ohos-rk3588-images\images\system.img
```

只勾选 **System**，地址保持 **`0x00029000`**。Boot 与用户刚完成全刷的版本逐字节相同，已通过 UART 对照校验；其他分区无须重刷，本次无需再次清除 Userdata。

新版本指纹会触发保留数据时的预装应用升级扫描。不要再重复刷 R1 或旧备份中的 System。

System SHA256：

```text
b3f5382450d20a6b9e7741a68bbb8f6f7e7e56148c70a12aafb980744d8ad55c
```

完整文件校验值见本目录 `SHA256SUMS.txt`。覆盖前的文件备份位于上一级 `backups/images-before-sceneboard-r2-20261105-163811` 目录。

## 修正的实际原因

该产品的 BMS 按预装清单安装应用，R1 清单漏了 `/system/app/SceneBoard`，所以即使全量刷写并初始化 Userdata，SceneBoard 也不会安装；旧桌面又被新架构开关禁用，导致卡在启动 Logo。

R2 已补上 SceneBoard 目录、限定签名的桌面启动能力配置，并更新增量版本标识。没有修改应用业务逻辑或清理板上数据库。

## 已完成的验证

- 整套 RK3588 系统构建通过，耗时 8 分 1 秒。
- 从实际 System 镜像确认预装目录、签名限定的能力项、增量版本均为修正值。
- SceneBoard 开关为 `ENABLED`，SA 4607 与所需服务/NAPI 库存在。
- 四个 SceneBoard HAP 的包名及版本一致、模块名无重复，ZIP 校验通过；主 HAP 与 Linux 源码构建产物 SHA256 一致。
- 四个 ext4 镜像只读检查通过；Boot FIT 载荷哈希校验通过；分区容量检查通过。
- Vendor、Sys-prod、Chip-prod 的文件内容、权限和链接目标与 R1 核对无差异。
- 本机覆盖后已逐文件核对构建机 SHA256。

R2 尚未在板上启动验收。SceneBoard 运行时依赖、桌面显示、双 HDMI、鼠标及稳定性仍需验证，不能保证后续没有其他问题。

详细记录：[预装清单修复 R2](../SceneBoard-预装清单修复-20261105.md)。证据：`../validation/cursor-20261105/sceneboard-preinstall-r2/`。

