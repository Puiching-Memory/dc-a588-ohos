import hashlib
import json
import pathlib
import re
import stat
import subprocess
import zipfile

root = pathlib.Path('/home/<user>/ohos/validation/sceneboard-image-20261105')
images = root / 'images'
evidence = root / 'evidence'
expected_hap = '7b21b08807499486d7ff0b711e95f2d6d8d33eeb2a23450bd1b0ed396f97163f'

def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as source:
        for block in iter(lambda: source.read(4 * 1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()

def debugfs(image, command):
    result = subprocess.run(['debugfs', '-R', command, str(image)], capture_output=True)
    errors = result.stderr.decode(errors='replace')
    if result.returncode or 'File not found' in errors or 'not found by ext2_lookup' in errors:
        raise RuntimeError(f'{image.name}: {command}: {errors}')
    return result.stdout

def extract_manifest(image, destination):
    destination.mkdir(parents=True, exist_ok=True)
    debugfs(image, f'rdump / {destination}')
    result = {}
    for path in sorted(destination.rglob('*')):
        relative = str(path.relative_to(destination))
        info = path.lstat()
        if stat.S_ISLNK(info.st_mode):
            result[relative] = {'type': 'symlink', 'target': str(path.readlink())}
        elif stat.S_ISREG(info.st_mode):
            result[relative] = {'type': 'file', 'sha256': digest(path), 'mode': stat.S_IMODE(info.st_mode)}
        elif stat.S_ISDIR(info.st_mode) and relative != 'lost+found':
            result[relative] = {'type': 'directory', 'mode': stat.S_IMODE(info.st_mode)}
    return result

parameter = (images / 'parameter.txt').read_text()
partitions = {name: (int(size, 16) * 512, int(offset, 16))
              for size, offset, name in re.findall(r'0x([0-9a-fA-F]+)@0x([0-9a-fA-F]+)\(([^)]+)\)', parameter)}
report = {'images': {}, 'partition_content_differences': {}}
for filename, partition in [('system.img', 'system'), ('boot.img', 'boot'), ('vendor.img', 'vendor'),
                            ('sys_prod.img', 'sys-prod'), ('chip_prod.img', 'chip-prod')]:
    path = images / filename
    capacity, offset = partitions[partition]
    assert 0 < path.stat().st_size <= capacity, f'{filename} exceeds partition capacity'
    sha = digest(path)
    original = root / 'original-images' / filename
    old_sha = digest(original)
    report['images'][filename] = {'bytes': path.stat().st_size, 'sha256': sha, 'original_sha256': old_sha,
                                 'unchanged': sha == old_sha, 'sector_offset': hex(offset), 'capacity': capacity}
    if filename != 'boot.img':
        check = subprocess.run(['e2fsck', '-f', '-n', str(path)], capture_output=True)
        (evidence / f'{filename}.e2fsck.txt').write_bytes(check.stdout + check.stderr)
        assert check.returncode == 0, f'Filesystem check failed: {filename}, exit {check.returncode}'
    if filename in ('vendor.img', 'sys_prod.img', 'chip_prod.img') and sha != old_sha:
        before = extract_manifest(original, root / 'partition-compare' / filename / 'before')
        after = extract_manifest(path, root / 'partition-compare' / filename / 'after')
        changed = [name for name in sorted(set(before) | set(after)) if before.get(name) != after.get(name)]
        report['partition_content_differences'][filename] = changed
        (evidence / f'{filename}.files-before.json').write_text(json.dumps(before, indent=2))
        (evidence / f'{filename}.files-after.json').write_text(json.dumps(after, indent=2))

local_baseline = root / 'local-original-images'
if local_baseline.is_dir():
    report['local_original_comparison'] = {}
    for filename in ['vendor.img', 'sys_prod.img', 'chip_prod.img']:
        baseline = local_baseline / filename
        if not baseline.is_file():
            continue
        baseline_sha = digest(baseline)
        entry = {'sha256': baseline_sha, 'unchanged': baseline_sha == report['images'][filename]['sha256']}
        if not entry['unchanged']:
            before = extract_manifest(baseline, root / 'partition-compare' / filename / 'local-before')
            after = extract_manifest(images / filename, root / 'partition-compare' / filename / 'after')
            entry['changed_paths'] = [name for name in sorted(set(before) | set(after)) if before.get(name) != after.get(name)]
            (evidence / f'{filename}.files-local-before.json').write_text(json.dumps(before, indent=2))
        report['local_original_comparison'][filename] = entry

system = images / 'system.img'
activation = debugfs(system, 'cat /system/etc/sceneboard.config').decode().strip()
assert activation == 'ENABLED', activation
report['sceneboard_activation'] = activation
profile = json.loads(debugfs(system, 'cat /system/profile/foundation.json'))
abilities = profile.get('systemability', [])
screen_ability = [item for item in abilities if item.get('name') == 4607]
assert len(screen_ability) == 1 and screen_ability[0].get('libpath') == 'libscreen_session_manager.z.so'
report['screen_service'] = screen_ability[0]
required_libraries = ['/system/lib64/platformsdk/libscreen_session_manager.z.so',
                      '/system/lib64/platformsdk/libscene_session_manager.z.so',
                      '/system/lib64/module/libscenesessionmanager_napi.z.so',
                      '/system/lib64/module/libscreensessionmanager_napi.z.so']
for library in required_libraries:
    output = debugfs(system, f'stat {library}').decode()
    assert 'Type: regular' in output, library
report['required_libraries'] = required_libraries
extracted = evidence / 'extracted-SceneBoard.hap'
debugfs(system, f'dump /system/app/SceneBoard/SceneBoard.hap {extracted}')
assert digest(extracted) == expected_hap, 'Image does not contain the validated SceneBoard HAP'
with zipfile.ZipFile(extracted) as package:
    assert package.testzip() is None
    module = json.loads(package.read('module.json'))
    assert module['app']['bundleName'] == 'com.ohos.sceneboard'
    assert module['module']['name'] == 'pad_sceneboard'
    report['app'] = {key: module['app'].get(key) for key in
                     ['bundleName', 'versionCode', 'versionName', 'compileSdkVersion', 'minAPIVersion', 'targetAPIVersion']}
    report['module'] = module['module']['name']
    report['hap_sha256'] = expected_hap
    report['device_types'] = module['module'].get('deviceTypes')
(evidence / 'image-inspection.json').write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')
print(json.dumps(report, indent=2, ensure_ascii=False))
