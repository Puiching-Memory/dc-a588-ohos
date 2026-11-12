import hashlib
import json
from pathlib import Path
import shutil
import ssl
import subprocess

source = Path('/home/<user>/ohos/src')
root = Path('/home/<user>/ohos/validation/sceneboard-preinstall-r2-20261105')
evidence = root / 'evidence'
evidence.mkdir(parents=True, exist_ok=True)
vendor = source / 'vendor/rockchip/rk3588/preinstall-config'
profile = json.loads(Path('/home/<user>/ohos/validation/sceneboard-image-20261105/evidence/signatures/new-app-profile.json').read_text())
signature = hashlib.sha256(ssl.PEM_cert_to_DER_cert(profile['bundle-info']['distribution-certificate'])).hexdigest().upper()
assert profile['bundle-info']['bundle-name'] == 'com.ohos.sceneboard'
assert profile['bundle-info']['apl'] == 'system_core'
paths = [vendor / 'install_list.json', vendor / 'install_list_capability.json',
         source / 'base/startup/init/services/etc/param/ohos.para']
for path in paths:
    backup = root / 'source-backup' / path.relative_to(source)
    backup.parent.mkdir(parents=True, exist_ok=True)
    if not backup.exists():
        shutil.copy2(path, backup)

def add_record(path, record, key, identity):
    raw = path.read_bytes()
    document = json.loads(raw)
    existing = [entry for entry in document['install_list'] if entry.get(key) == identity]
    if existing:
        assert existing == [record], f'Conflicting existing record in {path}'
        return
    newline = b'\r\n' if b'\r\n' in raw else b'\n'
    marker = b'[' + newline
    assert raw.count(marker) >= 1
    lines = json.dumps(record, indent=4, ensure_ascii=False).splitlines()
    insertion = newline.join(('        ' + line).encode() for line in lines) + b',' + newline
    updated = raw.replace(marker, marker + insertion, 1)
    assert json.loads(updated)['install_list'][0] == record
    path.write_bytes(updated)

add_record(paths[0], {'app_dir': '/system/app/SceneBoard', 'removable': False}, 'app_dir', '/system/app/SceneBoard')
capability = {'bundleName': 'com.ohos.sceneboard', 'app_signature': [signature],
              'allowAppUsePrivilegeExtension': True, 'allowAbilityPriorityQueried': True,
              'allowAppRunWhenDeviceFirstLocked': True}
add_record(paths[1], capability, 'bundleName', 'com.ohos.sceneboard')
old = b'const.product.incremental.version=default'
new = b'const.product.incremental.version=sceneboard-preinstall-20261105-r2'
parameter = paths[2].read_bytes()
if new not in parameter:
    assert parameter.count(old) == 1
    paths[2].write_bytes(parameter.replace(old, new))
assert paths[2].read_bytes().count(new) == 1

for repository, filenames, label in [
    (source / 'vendor/rockchip', ['rk3588/preinstall-config/install_list.json', 'rk3588/preinstall-config/install_list_capability.json'], 'preinstall'),
    (source / 'base/startup/init', ['services/etc/param/ohos.para'], 'incremental-version')]:
    subprocess.run(['git', '-c', 'core.whitespace=blank-at-eol,blank-at-eof,space-before-tab,cr-at-eol',
                    '-C', str(repository), 'diff', '--check', '--', *filenames], check=True)
    patch = subprocess.check_output(['git', '-C', str(repository), 'diff', '--', *filenames])
    (evidence / f'{label}.patch').write_bytes(patch)
report = {'preinstall_directory': '/system/app/SceneBoard', 'capability': capability,
          'incremental_version': new.decode().split('=', 1)[1],
          'files': {str(path.relative_to(source)): hashlib.sha256(path.read_bytes()).hexdigest() for path in paths}}
(evidence / 'source-fix.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps(report, indent=2))

old_root = Path('/home/<user>/ohos/validation/sceneboard-image-20261105')
for name in ['build-sceneboard-image.sh', 'build-sceneboard-image-container.sh']:
    script = (old_root / name).read_text().replace('sceneboard-image-20261105', root.name)
    script = script.replace('args-classic.gn', 'args-before-r2.gn')
    (root / name).write_text(script)
backup_hap = root / 'SceneBoard.prebuilt.orig.hap'
if not backup_hap.exists():
    shutil.copy2(source / 'applications/standard/hap/sceneboard/SceneBoard.hap', backup_hap)
original_images = root / 'original-images'
if not original_images.exists():
    original_images.symlink_to(old_root / 'images', target_is_directory=True)
