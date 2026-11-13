"""Offline regression checks; no downloads, vendor GUI, or board writes.

Run: python -m unittest discover -s tests -v
"""
# SPDX-License-Identifier: Apache-2.0
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
BASH = shutil.which('bash') or (
    str(Path(os.environ.get('ProgramFiles', 'C:/Program Files')) / 'Git/bin/bash.exe')
    if os.name == 'nt' else None
)
POWERSHELL = shutil.which('powershell.exe') or shutil.which('pwsh')


@unittest.skipUnless(BASH and Path(BASH).exists(), 'Bash required')
class LfsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ohos-lfs-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.source = self.root / 'source tree'
        self.bin = self.root / 'bin'
        self.source.mkdir()
        self.bin.mkdir()
        for name in ('ok project', 'failed-project'):
            (self.source / name).mkdir()
        self.write_tool('git', '''#!/usr/bin/env bash
if [[ $1 == lfs && $2 == version ]]; then exit 0; fi
printf '%s\\n' "$PWD" >> "$PULL_LOG"
if [[ ${PWD##*/} == failed-project ]]; then exit 42; fi
''')
        # Emulate repo's project listing and discovery failures without a checkout.
        self.write_tool('python3', '''#!/usr/bin/env bash
if [[ ${DISCOVERY_FAIL:-0} == 1 ]]; then exit 31; fi
printf 'ok project\\n'
''')
        self.env = dict(os.environ, OHOS_SOURCE_ROOT=self.source.as_posix(),
                        PULL_LOG=(self.root / 'pull.log').as_posix(),
                        TEST_BIN=str(self.bin))
        self.env['PATH'] = str(self.bin) + os.pathsep + self.env['PATH']

    def write_tool(self, name, text):
        path = self.bin / name
        path.write_text(text, encoding='utf-8', newline='\n')
        path.chmod(0o755)

    def run_lfs(self, projects=None):
        args = self.shell_args() + [
                (ROOT / 'scripts/build/lfspull.sh').as_posix()]
        if projects is not None:
            manifest = self.source / 'projects.txt'
            manifest.write_bytes(projects)
            args.append(manifest.as_posix())
        return subprocess.run(args, env=self.env, capture_output=True,
                              encoding='utf-8', timeout=20)

    def shell_args(self):
        # Git for Windows' launcher prepends its real git to PATH. Insert mocks
        # inside the shell so the test never calls git-lfs or the network.
        return [BASH, '--noprofile', '--norc', '-c',
                'if command -v cygpath >/dev/null; then TEST_BIN=$(cygpath -u "$TEST_BIN"); fi; '
                'export PATH="$TEST_BIN:$PATH"; script=$1; shift; source "$script" "$@"', 'release-test']

    def test_failure_survives_pipeline_and_later_projects_run(self):
        result = self.run_lfs(b'# explicit list\r\nfailed-project\r\n\r\nok project')
        self.assertEqual(result.returncode, 1, result.stderr)
        self.assertIn('FAILED (42): failed-project', result.stderr)
        self.assertIn('OK: ok project', result.stdout)
        self.assertIn('repositories: 2; failed: 1', result.stdout)

    def test_success_with_spaces_and_crlf(self):
        result = self.run_lfs(b'ok project\r\n')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('repositories: 1; failed: 0', result.stdout)

    def test_automatic_discovery(self):
        result = self.run_lfs()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('OK: ok project', result.stdout)

    def test_discovery_failure_does_not_report_success(self):
        self.env['DISCOVERY_FAIL'] = '1'
        result = self.run_lfs()
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'pull.log').exists())

    def test_missing_project_is_failure(self):
        result = self.run_lfs(b'absent\n')
        self.assertEqual(result.returncode, 1)
        self.assertIn('FAILED', result.stderr)

    def test_missing_list_is_failure(self):
        result = subprocess.run(
            self.shell_args() + [
             (ROOT / 'scripts/build/lfspull.sh').as_posix(),
             (self.root / 'absent.txt').as_posix()],
            env=self.env, capture_output=True, timeout=20)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'pull.log').exists())


@unittest.skipUnless(POWERSHELL and os.name == 'nt', 'Windows PowerShell required')
class FlashConfigTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='ohos-flash-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.tool = self.root / 'RK Tools'
        self.images = self.root / 'images \u4e2d\u6587'
        self.tool.mkdir()
        self.images.mkdir()

    def generate(self):
        return subprocess.run(
            [POWERSHELL, '-NoProfile', '-ExecutionPolicy', 'RemoteSigned', '-File',
             str(ROOT / 'scripts/flash/Prepare-FlashConfig.ps1'),
             '-ToolDirectory', str(self.tool), '-ImageDirectory', str(self.images)],
            capture_output=True, timeout=20)

    def test_only_paths_change_and_chinese_paths_roundtrip(self):
        result = self.generate()
        self.assertEqual(result.returncode, 0, result.stderr)
        original = bytearray((ROOT / 'scripts/flash/config.cfg').read_bytes())
        generated = bytearray((self.tool / 'config.cfg').read_bytes())
        self.assertEqual(len(original), len(generated))
        paths = 0
        for row in range(14):
            offset = 29 + row * 610 + 82
            before = bytes(original[offset:offset+520]).decode('utf-16-le').split('\0')[0]
            after = bytes(generated[offset:offset+520]).decode('utf-16-le').split('\0')[0]
            if before:
                name = before.rsplit('\\', 1)[1]
                self.assertEqual(after, str(self.images / name))
                self.assertTrue(before.startswith('..\\..\\images\\'))
                paths += 1
            else:
                self.assertEqual(after, '')
            original[offset:offset+520] = generated[offset:offset+520] = bytes(520)
        self.assertEqual(paths, 11)
        self.assertEqual(original, generated, 'Partition metadata must not change')

    def test_existing_config_is_preserved(self):
        output = self.tool / 'config.cfg'
        output.write_bytes(b'keep existing selections')
        result = self.generate()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(output.read_bytes(), b'keep existing selections')


if __name__ == '__main__':
    unittest.main()
