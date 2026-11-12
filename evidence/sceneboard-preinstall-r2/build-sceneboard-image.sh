#!/usr/bin/env bash
set -euo pipefail
SCB_IMAGE_ROOT=/home/<user>/ohos/validation/sceneboard-preinstall-r2-20261105
SCB_SOURCE=/home/<user>/ohos/src
SCB_HAP=$SCB_SOURCE/applications/standard/window_scene_board/product/pad/build/default/outputs/default/pad_sceneboard-default-signed.hap
SCB_PREBUILT=$SCB_SOURCE/applications/standard/hap/sceneboard/SceneBoard.hap
SCB_HAP_SHA=7b21b08807499486d7ff0b711e95f2d6d8d33eeb2a23450bd1b0ed396f97163f
test -f "$SCB_IMAGE_ROOT/SceneBoard.prebuilt.orig.hap"
printf '%s  %s\n' "$SCB_HAP_SHA" "$SCB_HAP" | sha256sum -c -
restore_prebuilt_hap() {
    local current_hash
    current_hash=$(sha256sum "$SCB_PREBUILT")
    current_hash=${current_hash%% *}
    if test "$current_hash" = "$SCB_HAP_SHA"; then
        cp -p "$SCB_IMAGE_ROOT/SceneBoard.prebuilt.orig.hap" "$SCB_PREBUILT"
    else
        echo 'SceneBoard prebuilt input changed externally; original input was not restored.' >&2
        return 1
    fi
}
cp -p "$SCB_SOURCE/out/rockchip/args.gn" "$SCB_IMAGE_ROOT/evidence/args-before-r2.gn"
cp --reflink=auto "$SCB_HAP" "$SCB_PREBUILT"
trap restore_prebuilt_hap EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$SCB_IMAGE_ROOT/evidence/system-build.started"
set +e
docker run --rm --user 1005:1005 -e HOME=/home/ohos -e CCACHE_DIR=/ccache \
  -v /home/<user>/ohos:/home/ohos -v /home/<user>/ohos/ccache:/ccache \
  -w /home/ohos/src ohos-6.1-rk:jammy-v3 \
  /bin/bash /home/ohos/validation/sceneboard-preinstall-r2-20261105/build-sceneboard-image-container.sh \
  > "$SCB_IMAGE_ROOT/evidence/system-build.log" 2>&1
SCB_BUILD_RESULT=$?
set -e
printf '%s\n' "$SCB_BUILD_RESULT" > "$SCB_IMAGE_ROOT/evidence/system-build.exit-code"
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$SCB_IMAGE_ROOT/evidence/system-build.finished"
if test "$SCB_BUILD_RESULT" -ne 0; then
    tail -65 "$SCB_IMAGE_ROOT/evidence/system-build.log"
    exit "$SCB_BUILD_RESULT"
fi
mkdir -p "$SCB_IMAGE_ROOT/images"
for image in system.img boot.img vendor.img sys_prod.img chip_prod.img parameter.txt; do
    cp -a --reflink=auto "$SCB_SOURCE/out/rockchip/packages/phone/images/$image" "$SCB_IMAGE_ROOT/images/$image"
done
cp -p "$SCB_SOURCE/out/rockchip/args.gn" "$SCB_IMAGE_ROOT/evidence/args-sceneboard.gn"
sha256sum "$SCB_IMAGE_ROOT"/images/* > "$SCB_IMAGE_ROOT/evidence/images.sha256"
echo SCENEBOARD_SYSTEM_BUILD_SUCCESS
