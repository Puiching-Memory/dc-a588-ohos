# 02 · 构建环境

## 1. 主机

| 项 | 值 |
| --- | --- |
| 地址 | `<BUILD_HOST>`，SSH 端口 **<SSH_PORT>**，用户 `<user>` |
| 系统 | Ubuntu 24.04（宿主），96 核 |
| 权限 | **无免密 sudo**；容器内以 `1005:1005` 运行 |
| 工作根目录 | `~/ohos`（源码在 `~/ohos/src`） |

本机（Windows）到构建机走直连 IP 字面量，不使用别名；批量命令用 `-o BatchMode=yes`。

## 2. 源码目录布局

```
~/ohos/
├── repo                     repo 工具（repo-py3，需要 bin/python -> python3）
├── bin/
├── src/                     repo 工作区（OpenHarmony-6.1-RK-LTS）
├── ccache/                  构建缓存（容器内挂到 /ccache）
├── prebuilts_cache/         挂到 /home/ohos/openharmony_prebuilts
├── Dockerfile               构建镜像定义
├── build-rk3588.sh          构建入口（宿主侧，挂载为 /build.sh）
├── sync.sh                  repo sync 带重试
├── lfspull.sh               按仓库列表拉 git-lfs
├── lfs_repos.txt            LFS 仓库清单
├── validation/              各专项验证（SceneBoard、预装修复、回退）
└── *.log                    每轮构建日志（build-align*/build-led/build-dsi/...）
```

## 3. 镜像

`Dockerfile` → `ohos-6.1-rk:jammy-v3`（基于 `ubuntu:22.04`，apt 源换 `mirrors.ustc.edu.cn`）：

- 基础链：`build-essential gcc g++ gcc-multilib libc6-dev-i386 binutils* flex bison gperf make cmake 依赖`
- OpenHarmony 构建需要：`device-tree-compiler u-boot-tools mtd-utils cpio liblz4-tool dosfstools mtools
  genext2fs e2fsprogs scons pkg-config ruby gnutls-bin xxd libgl1-mesa-dev libglib2.0-dev libpixman-1-dev`
- 额外补齐：`git-lfs libncurses5 libtinfo5 openjdk-8-jre-headless libstdc++-12-dev g++-multilib`
  （`g++-multilib` 是 rkaiq 宿主工具 `iq_parser_v2/j2s4b` 用 `-m32` 链接 `libstdc++` 的必要条件）
- 用户：`groupadd -g 1005 ohos && useradd -u 1005 -g 1005 -d /home/ohos ...`，`/ccache` 同权限

构建：

```bash
cd ~/ohos
docker build -t ohos-6.1-rk:jammy-v3 .
```

## 4. 运行容器

标准构建：

```bash
docker run --rm --user 1005:1005 -e HOME=/home/ohos \
  -v ~/ohos/src:/home/ohos/src \
  -v ~/ohos/ccache:/ccache \
  -v ~/ohos/prebuilts_cache:/home/ohos/openharmony_prebuilts \
  -v ~/ohos/build-rk3588.sh:/build.sh:ro \
  -w /home/ohos/src ohos-6.1-rk:jammy-v3 bash /build.sh
```

SceneBoard 实验则需要挂整个 `~/ohos`（脚本、SDK 副本、验证目录都在里面）：

```bash
docker run --rm --user 1005:1005 -e HOME=/home/ohos -e CCACHE_DIR=/ccache \
  -v /home/<user>/ohos:/home/ohos -v /home/<user>/ohos/ccache:/ccache \
  -w /home/ohos/src ohos-6.1-rk:jammy-v3 \
  /bin/bash /home/ohos/validation/sceneboard-image-20261105/build-sceneboard-image-container.sh
```

## 5. 网络与代理

- 远端 git 配置里有**失效代理**，repo/git 操作前必须清空：

```bash
export GIT_CONFIG_COUNT=2 \
       GIT_CONFIG_KEY_0=http.proxy  GIT_CONFIG_VALUE_0= \
       GIT_CONFIG_KEY_1=https.proxy GIT_CONFIG_VALUE_1=
```

  `sync.sh` / `lfspull.sh` 里已内置这两行。

- `~/ohos/repo` 是 repo-py3，脚本里用 `python3 ~/ohos/repo ...`；
  需要 `~/ohos/bin/python -> python3` 软链。
- LFS：`git lfs pull` 在部分仓库会超时，`lfspull.sh` 用 `timeout 1200` 逐仓库拉并记录返回码。

## 6. 从 Windows 侧操作

```powershell
ssh -o BatchMode=yes -p <SSH_PORT> <user>@<BUILD_HOST> '<command>'
scp -P <SSH_PORT> -o BatchMode=yes <user>@<BUILD_HOST>:~/ohos/build-rk3588.sh .\scripts\build\
```

注意：

- PowerShell 单引号字符串里的 `"` 在 native 传参时会被吞掉，**远程命令里避免用双引号**；
  复杂脚本先在本地写好再 `scp` 过去执行。
- 链路会抖动，`scp`/`ssh` 需要重试；`scp` 走 SFTP，进度条不可靠，按进程启动时间与速率估算。
- 长任务（构建、轮询）走后台异步，不要在同一 shell 里跑 `for ... sleep`（会占住 shell 且读到循环中间输出）。
