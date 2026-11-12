import hashlib
import json
import pathlib
import sys

manifest_path, sdk_path, output_path = sys.argv[1:]
manifest = json.loads(pathlib.Path(manifest_path).read_text())
sdk = pathlib.Path(sdk_path)
paths = {pathlib.Path(entry['destination']) for operation in ('copy', 'replace', 'remove')
         for entry in manifest[operation]}
paths.update(sdk / suffix for suffix in (
    'ets/oh-uni-package.json',
    'ets/build-tools/ets-loader/tsconfig.json',
    'ets/component/index-full.d.ts',
    'ets/build-tools/ets-loader/declarations/index-full.d.ts',
))
result = {str(path): hashlib.sha256(path.read_bytes()).hexdigest() if path.is_file() else None
          for path in sorted(paths)}
pathlib.Path(output_path).write_text(json.dumps(result, indent=2) + '\n')
