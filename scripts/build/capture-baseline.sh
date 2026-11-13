#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
set -euo pipefail
source_root=${OHOS_SOURCE_ROOT:-$HOME/ohos/src}
repo_tool=${REPO_TOOL:-$HOME/ohos/repo}
if (( $# != 1 )); then
    echo 'Usage: capture-baseline.sh NEW_OUTPUT_DIRECTORY' >&2
    exit 2
fi
# Refuse to merge a new capture into an older one.
mkdir -- "$1"
BASELINE_OUTPUT=$(cd "$1" && pwd)
export BASELINE_OUTPUT
cd "$source_root"
python3 "$repo_tool" manifest -r -o "$BASELINE_OUTPUT/manifest.xml"
python3 "$repo_tool" forall -c '
    set -eu
    destination="$BASELINE_OUTPUT/projects/$REPO_PATH"
    mkdir -p "$destination"
    git rev-parse HEAD > "$destination/HEAD.txt"
    git status --porcelain=v1 > "$destination/status.txt"
    git diff HEAD --binary > "$destination/tracked-changes.patch"
    git ls-files --others --exclude-standard > "$destination/untracked-files.txt"
'
printf '%s\n' 'Captured revisions and tracked changes. Review untracked-files.txt and submodules separately before calling this a complete source baseline.'
