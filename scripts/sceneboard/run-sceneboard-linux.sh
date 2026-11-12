#!/usr/bin/env bash
set -euo pipefail
SCB_RUN_ROOT=/home/<user>/ohos/validation/sceneboard-linux-20261105
SCB_PROJECT=/home/<user>/ohos/src/applications/standard/window_scene_board
SCB_TOOL=/home/<user>/ohos/src/prebuilts/tool/command-line-tools/6.x/hvigor/bin/hvigorw.js
SCB_TARGET=${1:-pad_sceneboard}
case "$SCB_TARGET" in pad_sceneboard|phone_sceneboard|pc_sceneboard) ;; *) exit 2 ;; esac
SCB_LABEL=${2:-$SCB_TARGET}
case "$SCB_LABEL" in ''|*[!a-zA-Z0-9_-]*) exit 2 ;; esac
if test -f "$SCB_RUN_ROOT/evidence/java-home.txt"; then
    SCB_JAVA_HOME=$(cat "$SCB_RUN_ROOT/evidence/java-home.txt")
    case "$SCB_JAVA_HOME" in "$SCB_RUN_ROOT"/java/*) ;; *) exit 2 ;; esac
    test -x "$SCB_JAVA_HOME/bin/java"
    export JAVA_HOME="$SCB_JAVA_HOME"
    export PATH="$JAVA_HOME/bin:$PATH"
fi
SCB_BACKUP=$(mktemp "$SCB_RUN_ROOT/evidence/local.properties.$SCB_TARGET.XXXXXX")
cp -p "$SCB_PROJECT/local.properties" "$SCB_BACKUP"
restore_scb_properties() {
    cp -p "$SCB_BACKUP" "$SCB_PROJECT/local.properties"
}
trap restore_scb_properties EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
printf 'sdk.dir=%s\n' "$SCB_RUN_ROOT/sdk" > "$SCB_PROJECT/local.properties"
export OHOS_SDK_HOME="$SCB_RUN_ROOT/sdk"
export NODE_OPTIONS=--max-old-space-size=20000
export PATH=/home/<user>/ohos/src/prebuilts/tool/command-line-tools/6.x/hvigor/bin:$PATH
cd "$SCB_PROJECT"
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$SCB_RUN_ROOT/evidence/$SCB_LABEL.started"
set +e
node "$SCB_TOOL" assembleHap --mode module -p product=default \
    -p "module=$SCB_TARGET@default" -p buildMode=release --no-daemon --stacktrace \
    > "$SCB_RUN_ROOT/evidence/$SCB_LABEL.log" 2>&1
SCB_RESULT=$?
set -e
printf '%s\n' "$SCB_RESULT" > "$SCB_RUN_ROOT/evidence/$SCB_LABEL.exit-code"
date -u +'%Y-%m-%dT%H:%M:%SZ' > "$SCB_RUN_ROOT/evidence/$SCB_LABEL.finished"
printf 'SCENEBOARD_BUILD_EXIT=%s\n' "$SCB_RESULT"
grep -E 'Current sdk version|Update SDK interface|preparation verified|BUILD SUCCESS|BUILD FAILED|COMPILE RESULT' \
    "$SCB_RUN_ROOT/evidence/$SCB_LABEL.log" | tail -8 || true
exit "$SCB_RESULT"
