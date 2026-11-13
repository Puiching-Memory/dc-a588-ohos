#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
source_root=${OHOS_SOURCE_ROOT:-$HOME/ohos/src}
repo_tool=${REPO_TOOL:-$HOME/ohos/repo}
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=http.proxy GIT_CONFIG_VALUE_0= GIT_CONFIG_KEY_1=https.proxy GIT_CONFIG_VALUE_1=
cd "$source_root"
for attempt in $(seq 1 30); do
    printf 'Sync attempt %s: %s\n' "$attempt" "$(date -Iseconds)"
    if python3 "$repo_tool" sync -c --force-sync --no-tags --jobs=16 --retry-fetches=3; then
        echo 'SYNC OK'
        exit 0
    fi
    if (( attempt < 30 )); then sleep 60; fi
done
echo 'SYNC GAVE UP' >&2
exit 1
