import hashlib
import json
from pathlib import Path
import re
import shutil

source = Path('/home/<user>/ohos/src')
experiment = Path('/home/<user>/ohos/validation/sceneboard-preinstall-r2-20261105')
fix = json.loads((experiment / 'evidence/source-fix.json').read_text())
restorations = []
for relative, expected in fix['files'].items():
    path = source / relative
    backup = experiment / 'source-backup' / relative
    current = hashlib.sha256(path.read_bytes()).hexdigest()
    original = hashlib.sha256(backup.read_bytes()).hexdigest()
    if current not in (expected, original):
        raise RuntimeError(f'Source changed after the experiment; refusing to overwrite: {relative}')
    restorations.append((relative, path, backup, original))

restored = {}
for relative, path, backup, original in restorations:
    shutil.copy2(backup, path)
    assert hashlib.sha256(path.read_bytes()).hexdigest() == original
    restored[relative] = original

args = source / 'out/rockchip/args.gn'
raw = args.read_text()
backup_args = experiment / 'evidence/args-before-abandon.gn'
if not backup_args.exists():
    shutil.copy2(args, backup_args)
pattern = r'(?m)^window_manager_use_sceneboard[ \t]*=[ \t]*(true|false)[ \t]*$'
assert len(re.findall(pattern, raw)) == 1
updated = re.sub(pattern, 'window_manager_use_sceneboard = false', raw)
if updated != raw:
    args.write_text(updated)
report = {'status': 'sceneboard-direction-abandoned-at-user-request', 'restored_source_files': restored,
          'window_manager_use_sceneboard': False, 'new_build_executed': False,
          'retained': ['Linux SDK preparation source fixes', 'classic cursor rsId source fix',
                       'original MoveSoft patch', 'other pre-existing worktree changes']}
(experiment / 'evidence/abandoned-state.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))
