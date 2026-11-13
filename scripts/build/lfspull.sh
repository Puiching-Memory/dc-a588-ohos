#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail

# Run from a repo workspace. An optional list contains paths relative to it.
source_root=${OHOS_SOURCE_ROOT:-$HOME/ohos/src}
repo_tool=${REPO_TOOL:-$HOME/ohos/repo}
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=http.proxy GIT_CONFIG_VALUE_0= GIT_CONFIG_KEY_1=https.proxy GIT_CONFIG_VALUE_1=
cd "$source_root"
git lfs version >/dev/null
timeout_seconds=${LFS_TIMEOUT_SECONDS:-1200}
[[ $timeout_seconds =~ ^[1-9][0-9]*$ ]] || { echo 'Invalid LFS_TIMEOUT_SECONDS' >&2; exit 2; }

if (( $# > 1 )); then
    echo 'Usage: lfspull.sh [repository-list.txt]' >&2
    exit 2
fi
repository_list=$(mktemp)
trap 'rm -f "$repository_list"' EXIT
if (( $# == 1 )); then
    cat -- "$1" > "$repository_list"
else
    # Check committed attributes in each project; git-lfs handles its own filters.
    python3 "$repo_tool" forall -c 'git grep -q "filter=lfs" HEAD -- .gitattributes ":(glob)**/.gitattributes"; result=$?; case "$result" in 0) printf "%s\n" "$REPO_PATH" ;; 1) : ;; *) exit "$result" ;; esac' > "$repository_list"
fi

failed=0
total=0
while IFS= read -r project || [[ -n $project ]]; do
    project=${project%$'\r'}
    [[ -z $project || $project == \#* ]] && continue
    total=$((total + 1))
    printf '\nLFS: %s\n' "$project"
    # pipefail preserves git/timeout failures instead of returning tail's status.
    if (cd "$project" && timeout "$timeout_seconds" git lfs pull </dev/null 2>&1 | tail -n 20); then
        printf 'OK: %s\n' "$project"
    else
        result=$?
        printf 'FAILED (%s): %s\n' "$result" "$project" >&2
        failed=$((failed + 1))
    fi
done < "$repository_list"
printf '\nLFS repositories: %s; failed: %s\n' "$total" "$failed"
(( failed == 0 ))
