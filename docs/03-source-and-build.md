# 03 · 源码同步与构建

## 1. 初始化 repo

先从 [gitcode-dev/repo](https://gitcode.com/gitcode-dev/repo) 获取 Python 3 版 repo 工具，
将其启动文件放在 `~/ohos/repo`，并记录实际版本。以下命令中的 `~/ohos/src` 为独立的 OpenHarmony
源码工作区，不是本归档仓库；容器和脚本准备见 [构建环境](02-build-environment.md)。

```bash
mkdir -p ~/ohos/src && cd ~/ohos/src
export PATH=~/ohos/bin:$PATH
export GIT_CONFIG_COUNT=2 \
       GIT_CONFIG_KEY_0=http.proxy  GIT_CONFIG_VALUE_0= \
       GIT_CONFIG_KEY_1=https.proxy GIT_CONFIG_VALUE_1=

python3 ~/ohos/repo init \
  -u https://gitcode.com/caesar-wang/manifest \
  -b OpenHarmony-6.1-RK-LTS \
  -m chipsets/rockchip.xml

python3 ~/ohos/repo sync -c --force-sync --no-tags --jobs=16 --retry-fetches=3
```

- manifest 仓库：`https://gitcode.com/caesar-wang/manifest`（RK3588 OpenHarmony 移植工程），
  分支 `OpenHarmony-6.1-RK-LTS`，`.repo/manifest.xml` 里 `<include name="chipsets/rockchip.xml" />`。
  本次构建机的 `.repo/manifests` remote 记录为 `gitcode.com/ning-bb/manifest`；复现时以上游
  `caesar-wang/manifest` 为准。
- repo 工具：`https://gitcode.com/gitcode-dev/repo`（repo-py3）。
- `sync.sh` = 上面的 sync 循环 30 次、每次失败等 60 s，适合弱网。
- `lfspull.sh` 默认用 `repo forall` 自动发现已提交 `.gitattributes` 含 `filter=lfs` 的项目，
  逐仓库 `git lfs pull`（默认 `timeout 1200`），不再依赖未归档的 `lfs_repos.txt`。
  自定义清单每行是相对源码根目录的项目路径，支持空行与 `#` 注释。

```bash
# 在本归档仓库根目录执行；默认源码目录为 ~/ohos/src。
bash scripts/build/sync.sh
bash scripts/build/lfspull.sh
# 可选：使用自己的清单（文件名使用绝对路径）。
bash scripts/build/lfspull.sh "$HOME/ohos/lfs_repos.txt"
```

`OHOS_SOURCE_ROOT`、`REPO_TOOL` 可覆盖源码和 repo 工具路径，`LFS_TIMEOUT_SECONDS` 可调整单项目超时。
项目失败后会继续检查其他项目，最终返回非零；自动发现失败、清单不存在或源码目录不可用也会失败。
新加而未提交的 LFS 属性应通过自定义清单覆盖。

## 2. prebuilts

首次构建会自动执行 `./build/prebuilts_download.sh`，脚本用 `.prebuilts_done` 标记跳过。
为了复用，容器把宿主 `~/ohos/prebuilts_cache` 挂到 `/home/ohos/openharmony_prebuilts`。

SDK 位置：`prebuilts/ohos-sdk/linux/23`，元数据 **API 23 / 6.1.0.47**。

## 3. 构建命令

`scripts/build/build-rk3588.sh`：

```bash
export CCACHE_DIR=/ccache
export PATH=/home/ohos/bin:/home/ohos/src/prebuilts/cmake/linux-x86/bin:\
/home/ohos/src/prebuilts/build-tools/linux-x86/bin:\
/home/ohos/src/prebuilts/ohos-sdk/linux/23/toolchains:$PATH
cd /home/ohos/src
if [ ! -f .prebuilts_done ]; then ./build/prebuilts_download.sh; touch .prebuilts_done; fi
./build.sh --product-name rk3588 --ccache --deps-guard false --gn-args \
  "window_manager_use_sceneboard=false allow_sanitize_debug=true is_use_check_deps=false \
   linux_kernel_version=linux-6.6 \
   linux_kernel_dtsname=rk3588-evb7-v11-standard \
   linux_kernel_config=\"rockchip_standard_defconfig rk3588_ohos.config\" \
   linux_kernel_image=Image \
   uboot_config=rk3588-ohos"
source out/.loader.cmd
source out/.kernel.cmd
```

要点：

- 产品形态 `rk3588`（standard / arm64）由 `vendor/rockchip/rk3588/config.json` 的 `type` 决定，
  standard 形态**必须**传 `linux_kernel_version` / `linux_kernel_dtsname` / `linux_kernel_config` /
  `linux_kernel_image` / `uboot_config`；RV1126B（`rv1126b`，small/arm）相反，只传 `--product-name`。
- 内核配置 = `rockchip_standard_defconfig` + `rk3588_ohos.config`，后者是仓库自带的产品增量配置
  （本工程在其中补了 `CONFIG_LEDS_TRIGGER_HEARTBEAT=y`，否则 `linux,default-trigger = "heartbeat"` 无效、状态灯常灭）。
- `source out/.loader.cmd` / `out/.kernel.cmd` 是构建脚本生成的单步重跑命令，改 dts 后重编内核用它们最快。
- 经典构建入口显式传 `window_manager_use_sceneboard=false`，避免复用实验输出目录时继承旧值；
  `true` 只用于 SceneBoard 实验脚本
  （见 [08-sceneboard-experiment.md](08-sceneboard-experiment.md)）。

## 4. 产物

`out/rockchip/packages/phone/images/`：

| 文件 | 大小 | 说明 |
| --- | --- | --- |
| `MiniLoaderAll.bin` | 547 KB | loader（DDR 初始化 + SPL） |
| `parameter.txt` | 535 B | GPT 分区表 |
| `uboot.img` | 4 MB | U-Boot proper + ATF + OP-TEE 的 FIT |
| `boot.img` | 48.6 MB | FIT：内核 + ramdisk + DTB |
| `system.img` | 2.0 GB | 系统分区 |
| `vendor.img` | 268 MB | 厂商分区 |
| `sys_prod.img` | 52 MB | 系统产品分区 |
| `chip_prod.img` | 52 MB | 芯片产品分区 |
| `userdata.img` | 1.4 GB | 用户数据（grow） |
| `updater.img` | 22 MB | 升级分区 |
| `eng_system.img` | 12 MB | 工程模式系统分区 |
| `ramdisk.img` | 2.8 MB | 已包含在 `boot.img` 内 |
| `Image` | 44.3 MB | 独立内核，供调试 |
| `rk3588-evb7-v11-standard.dtb` | 203 KB | 独立设备树，供调试 |

## 5. 增量构建

- **只改 dts / 内核**：`source out/.kernel.cmd` 重编内核与 boot 用到的 FIT 分量，约 10 分钟量级；
  再按 [05-flashing.md](05-flashing.md) 只烧 `boot`。
- **只改预装配置 / 系统应用**：重新运行系统构建入口，或按 SceneBoard 脚本出 `system.img`（历史约 8 分钟）。
  `out/.loader.cmd` 是 loader 构建入口，不能用于重建系统应用和预装清单。
- ccache 命中后整系统构建可到 8 分钟；首次 `CompileArkTS`（SceneBoard）约 6 分 30 秒。

## 6. 可复现性

- 内核编译时间戳等因素可能使 `Image` / `boot.img` 哈希变化；相同输入生成的 DTB 可单独比较。
  **DTB 哈希只用于核对设备树，不能代表内核、系统或整套固件版本。**
- `images/SHA256SUMS.txt` 标识历史归档镜像字节内容，新构建必须生成自己的完整镜像校验清单。
  哈希相同只能证明文件一致，不能代替实机验收。
- 本归档未保存历史完整的 `repo manifest -r`，部分本地改动也未完整归档。
  当前分支入口不能保证重建历史镜像；可用材料、缺口和后续基线留存方法见
  [11-reproducibility.md](11-reproducibility.md)。
