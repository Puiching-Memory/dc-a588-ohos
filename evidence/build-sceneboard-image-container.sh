#!/usr/bin/env bash
set -euo pipefail
export CCACHE_DIR=/ccache
export PATH=/home/ohos/bin:/home/ohos/src/prebuilts/cmake/linux-x86/bin:/home/ohos/src/prebuilts/build-tools/linux-x86/bin:/home/ohos/src/prebuilts/ohos-sdk/linux/23/toolchains:$PATH
cd /home/ohos/src
./build.sh --product-name rk3588 --ccache --deps-guard false --gn-args \
  'window_manager_use_sceneboard=true allow_sanitize_debug=true is_use_check_deps=false linux_kernel_version=linux-6.6 linux_kernel_dtsname=rk3588-evb7-v11-standard linux_kernel_config="rockchip_standard_defconfig rk3588_ohos.config" linux_kernel_image=Image uboot_config=rk3588-ohos'
