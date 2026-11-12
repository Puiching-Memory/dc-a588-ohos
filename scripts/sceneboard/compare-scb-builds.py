import collections
import json
import pathlib
import re
import sys

def summarize(filename):
    text = pathlib.Path(filename).read_text(encoding='utf-8', errors='replace')
    text = re.sub(r'\x1b\[[0-9;]*m', '', text)
    messages = re.findall(r'Error Message: (.+?)(?: At File:|\n)', text)
    missing = collections.Counter(name for message in messages
        for name in re.findall(r"Cannot find module '([^']+)'", message))
    all_missing = re.findall(r"Cannot find module '([^']+)'", text)
    return {
        'log': str(filename),
        'compile_results': re.findall(r'COMPILE RESULT:[^\r\n]+', text),
        'build_results': re.findall(r'BUILD (?:SUCCESSFUL|SUCCESS|FAILED)[^\r\n]*', text),
        'diagnostic_messages': len(messages),
        'missing_module_messages': sum(missing.values()),
        'missing_modules': dict(missing.most_common()),
        'non_error_missing_module_mentions': len(all_missing) - sum(missing.values()),
        'arkts_warning_blocks': len(re.findall(r'WARN: ArkTS:WARN File:', text)),
        'missing_member_messages': sum('does not exist on type' in x or 'has no exported member' in x for x in messages),
        'examples': messages[:12],
        'sdk_preparation_verified': 'SceneBoard SDK interface preparation verified:' in text,
    }

before, after, output = sys.argv[1:]
result = {'before': summarize(before), 'after': summarize(after)}
pathlib.Path(output).write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
print(json.dumps(result, indent=2, ensure_ascii=False))
