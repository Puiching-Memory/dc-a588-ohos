# SceneBoard 预装清单修复 R2

**已停止采用。** 用户决定放弃该方向，当前 `images/` 已恢复经典版本，下面保留实验记录，不再代表当前交付。见 [经典版本回退](SceneBoard-停用与经典版本回退-20261105.md)。

日期：2026-11-05。当前状态：R2 整套系统重编通过，耗时 8 分 1 秒；镜像内修正项、文件系统和 HAP 检查均通过，已下载并直接覆盖原 `images/`，覆盖后六个文件的 SHA256 均匹配构建机。本次只需刷 System。尚未在板上验证 R2。

## 全刷后仍卡 Logo 的原因

全刷后的 UART 记录证明账号和包数据库已重新生成，但 `installed_bundle` 中仍没有 `com.ohos.sceneboard`。旧 Launcher 和 SystemUI 又被 SceneBoard 开关禁用，因此没有可启动的桌面。

真正漏项在产品预装配置：BMS 的实际编译参数包含 `USE_PRE_BUNDLE_PROFILE`，启用了按清单安装。板上的 `/system/etc/app/install_list.json` 未包含 `/system/app/SceneBoard`。HAP 虽然被复制进 System，首次启动并不会安装清单以外的该目录。

此前关于旧 Userdata 和产品指纹的检查揭示了另一个迁移阻塞，但不足以解释全部问题。“全刷即可解决”的判断不完整；即使初始化 Userdata，错误的预装清单依然使 SceneBoard 被漏装。

## 修正

构建机源码前缀：`/home/<user>/ohos/src/`。

1. `vendor/rockchip/rk3588/preinstall-config/install_list.json`：增加不可卸载的 `/system/app/SceneBoard`。
2. 同目录 `install_list_capability.json`：增加 SceneBoard 的特权扩展、桌面优先级查询及首次锁定时运行能力。限定包名 `com.ohos.sceneboard` 和已验证的发布签名指纹 `8E93863FC32EE238060BF69A9B37E2608FFFB21F93C862DD511CBAC9F30024B5`；没有复制 SystemUI 的 singleton 配置。
3. `base/startup/init/services/etc/param/ohos.para`：将本次验证镜像的 `const.product.incremental.version` 设为 `sceneboard-preinstall-20261105-r2`，触发已有数据上的系统应用升级扫描。这个值是本次测试构建的版本标识，后续产品化应纳入产品版本管理。

BMS 的 `bundle_install_checker.cpp` 会在缺少 `allowAbilityPriorityQueried` 时将桌面扩展的 priority 清零，因此不仅需要把目录加入安装清单，还需要对应的桌面能力配置。

SceneBoard HAP 沿用已经通过 Linux 源码编译、签名和哈希核对的产物，本轮不改应用业务逻辑。

## 验证及边界

源码 JSON 校验、签名指纹核对及保留 CRLF 的定向 `git diff --check` 已通过。镜像检查新增了预装目录、签名限定的能力项及增量版本的断言，同时保留文件系统、服务库和 HAP 哈希检查。

R2 System SHA256 为 `b3f5382450d20a6b9e7741a68bbb8f6f7e7e56148c70a12aafb980744d8ad55c`。Boot 与 R1 逐字节一致，且 UART 读取的板上 Boot 哈希匹配；Vendor 及两个 Prod 的文件内容核对无差异。本次只需更新 System，地址 `0x00029000`，可保留当前 Userdata。

覆盖前的文件备份：`backups/images-before-sceneboard-r2-20261105-163811/`。本轮没有操作板上安装、参数、重启或烧录。

四个 SceneBoard HAP 的包名、版本一致、模块无重复，ZIP CRC 均通过。镜像内三个修正项均已核对源配置。尚未确认 SceneBoard 实际启动、外部模块解析、双 HDMI、鼠标和长期稳定性。

证据目录：`validation/cursor-20261105/sceneboard-preinstall-r2/`，其中 `evidence/image-inspection.json` 为实际镜像检查结果，`preinstall.patch`、`incremental-version.patch` 为定向源码补丁。

全刷现场证据：`validation/cursor-20261105/sceneboard-fullflash-*.txt` 及相应 `.raw.txt`。
