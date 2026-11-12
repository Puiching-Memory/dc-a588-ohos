#!/bin/bash
export PATH=/home/<user>/ohos/bin:$PATH
export GIT_CONFIG_COUNT=2 GIT_CONFIG_KEY_0=http.proxy GIT_CONFIG_VALUE_0= GIT_CONFIG_KEY_1=https.proxy GIT_CONFIG_VALUE_1=
cd /home/<user>/ohos/src
for i in $(seq 1 30); do
  echo "=== attempt $i $(date +%F" "%H:%M:%S) ==="
  python3 /home/<user>/ohos/repo sync -c --force-sync --no-tags --jobs=16 --retry-fetches=3 && { echo "=== SYNC OK $(date) ==="; exit 0; }
  echo "=== attempt $i failed, retry in 60s ==="
  sleep 60
done
echo "=== SYNC GAVE UP ==="; exit 1
