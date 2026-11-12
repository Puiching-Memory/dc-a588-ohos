#!/bin/bash
export PATH=/home/<user>/ohos/bin:$PATH
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=http.proxy GIT_CONFIG_VALUE_0= GIT_CONFIG_KEY_1=https.proxy GIT_CONFIG_VALUE_1=
while read -r d; do
    echo "=== $d"
    ( cd "$d" && timeout 1200 git lfs pull 2>&1 | tail -3 )
    echo "rc=$?"
done < /home/<user>/ohos/lfs_repos.txt
echo "=== ALL DONE"
