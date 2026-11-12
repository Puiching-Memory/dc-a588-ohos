import hashlib
import json
from pathlib import Path
import struct

root = Path('/home/<user>/ohos/validation/sceneboard-image-20261105')

def inspect(path):
    raw = path.read_bytes()
    magic, total, structure, strings = struct.unpack_from('>4I', raw)
    assert magic == 0xd00dfeed
    position = structure
    stack = []
    nodes = {}
    while True:
        token, = struct.unpack_from('>I', raw, position)
        position += 4
        if token == 1:
            end = raw.index(b'\0', position)
            stack.append(raw[position:end].decode())
            position = (end + 4) & ~3
            nodes['/'.join(stack)] = {}
        elif token == 2:
            stack.pop()
        elif token == 3:
            length, name_offset = struct.unpack_from('>2I', raw, position)
            position += 8
            name_end = raw.index(b'\0', strings + name_offset)
            name = raw[strings + name_offset:name_end].decode()
            nodes['/'.join(stack)][name] = raw[position:position + length]
            position = (position + length + 3) & ~3
        elif token == 4:
            continue
        elif token == 9:
            break
        else:
            raise ValueError(token)
    images = {}
    for name, props in nodes.items():
        if name.count('/') != 2 or not name.startswith('/images/'):
            continue
        if 'data' in props:
            data = props['data']
        else:
            size = int.from_bytes(props['data-size'], 'big')
            if 'data-position' in props:
                offset = int.from_bytes(props['data-position'], 'big')
            else:
                offset = ((total + 3) & ~3) + int.from_bytes(props['data-offset'], 'big')
            data = raw[offset:offset + size]
            assert len(data) == size
        images[name] = {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        for child, attributes in nodes.items():
            if child.startswith(name + '/hash'):
                algorithm = attributes['algo'].rstrip(b'\0').decode()
                assert hashlib.new(algorithm, data).digest() == attributes['value'], child
    assert images
    return {'images': images, 'fit_timestamp': int.from_bytes(nodes[''].get('timestamp', b''), 'big')}

before = inspect(root / 'original-images/boot.img')
after = inspect(root / 'images/boot.img')
result = {'before': before, 'after': after, 'all_payloads_identical': before['images'] == after['images']}
(root / 'evidence/boot-fit-comparison.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
