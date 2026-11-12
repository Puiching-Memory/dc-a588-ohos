#!/usr/bin/env python3
"""
比对两个 RK3588 反编译设备树（dts），输出：
  1. 双方都存在的节点里，status 不一致的
  2. 双方都存在的节点里，GPIO 类属性解码后不一致的
  3. 只在其中一侧出现的、带 GPIO 属性的节点
GPIO 属性会被解码成 (bank, pin, flags)，便于直接对照引脚。
"""

import re
import sys

GPIO_PROP_RE = re.compile(r'gpio', re.I)


def strip_comments(text):
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
    text = re.sub(r'//[^\n]*', '', text)
    return text


def parse_dts(path):
    """返回 (nodes, ) ；nodes 是 dict: path -> {'props': [(name, raw)], 'children': set}"""
    text = strip_comments(open(path, encoding='utf-8', errors='replace').read())
    nodes = {'/': {'props': [], 'children': []}}
    stack = [('/')]
    buf = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == '{':
            header = ''.join(buf).strip()
            buf = []
            name = header
            # 形如 "label: node@addr" 或 "node@addr: label"
            if ':' in header:
                parts = [p.strip() for p in header.split(':')]
                # 取不含 '@' 和 ' ' 更像 label 的；否则取另一个
                cand = [p for p in parts if p]
                if len(cand) == 2:
                    name = cand[1] if '@' in cand[0] else cand[0]
                else:
                    name = cand[0]
            name = name.strip()
            parent = stack[-1]
            p = (parent.rstrip('/') + '/' + name) if parent != '/' else '/' + name
            if p not in nodes:
                nodes[p] = {'props': [], 'children': []}
            nodes[parent]['children'].append(name)
            stack.append(p)
            i += 1
            continue
        if c == '}':
            buf = []
            if len(stack) > 1:
                stack.pop()
            i += 1
            continue
        if c == ';':
            stmt = ''.join(buf).strip()
            buf = []
            if stmt and '=' in stmt:
                name, val = stmt.split('=', 1)
                nodes[stack[-1]]['props'].append((name.strip(), val.strip()))
            i += 1
            continue
        buf.append(c)
        i += 1
    return nodes


def prop_map(node):
    d = {}
    for k, v in node['props']:
        d[k] = v
    return d


def cells(raw):
    """把 <0x1 0x2> 或 <0x1 0x2>, <0x3 0x4> 解析成整数列表"""
    return [int(x, 16) for x in re.findall(r'0x[0-9a-fA-F]+', raw)]


def build_maps(nodes):
    ph2path = {}
    for path, node in nodes.items():
        pm = prop_map(node)
        if 'phandle' in pm:
            v = cells(pm['phandle'])
            if v:
                ph2path[v[0]] = path
    # __symbols__: gpioN -> path（我方有；厂商反编译 dtb 通常没有）
    bank_of_path = {}
    sym = nodes.get('/__symbols__')
    if sym:
        for k, v in sym['props']:
            m = re.fullmatch(r'gpio(\d)', k)
            if m:
                p = v.strip().strip('"')
                bank_of_path[p] = int(m.group(1))
    # 兜底：按 gpio 控制器的 reg 地址排序推断 bank（RK3588 地址递增即 bank0..4）
    found = []
    for path, node in nodes.items():
        if not re.search(r'gpio@', path):
            continue
        if path in bank_of_path:
            continue
        pm = prop_map(node)
        reg = pm.get('reg')
        if not reg:
            continue
        cs = cells(reg)
        if not cs:
            continue
        # reg = <addr_hi addr_lo size_hi size_lo>
        base = cs[1] if len(cs) >= 2 else cs[0]
        found.append((base, path))
    for idx, (base, path) in enumerate(sorted(found)):
        bank_of_path.setdefault(path, idx)
    return ph2path, bank_of_path


def decode_gpios(nodes, ph2path, bank_of_path):
    """返回 dict: (nodepath, propname) -> [(bank,pin,flags), ...]"""
    out = {}
    for path, node in nodes.items():
        for name, raw in node['props']:
            if not GPIO_PROP_RE.search(name):
                continue
            if '<' not in raw:
                continue
            cs = cells(raw)
            dec = []
            ok = True
            for j in range(0, len(cs) - 2, 3):
                ph, pin, flags = cs[j], cs[j + 1], cs[j + 2]
                tgt = ph2path.get(ph)
                bank = bank_of_path.get(tgt) if tgt else None
                if bank is None:
                    ok = False
                    break
                dec.append((bank, pin, flags))
            if dec:
                out[(path, name)] = dec
            elif not ok:
                out[(path, name)] = [('?', '?', '?')]
    return out


def pin_name(bank, pin, flags):
    if bank == '?' or pin == '?':
        return '?'
    grp = 'ABCD'[pin // 8] if isinstance(pin, int) and pin < 32 else '?'
    num = pin % 8 if isinstance(pin, int) else '?'
    pol = ''
    if isinstance(flags, int):
        pol = 'LOW' if (flags & 1) else 'HIGH'
    return f'GPIO{bank}_{grp}{num}/{pol}'


def norm_prop(v):
    return re.sub(r'\s+', ' ', v).strip()


def main(ours_path, vendor_path):
    ours = parse_dts(ours_path)
    vend = parse_dts(vendor_path)

    o_ph, o_bank = build_maps(ours)
    v_ph, v_bank = build_maps(vend)

    o_gpio = decode_gpios(ours, o_ph, o_bank)
    v_gpio = decode_gpios(vend, v_ph, v_bank)

    o_pm = {p: prop_map(n) for p, n in ours.items()}
    v_pm = {p: prop_map(n) for p, n in vend.items()}

    both = sorted(set(o_pm) & set(v_pm))
    only_o = sorted(set(o_pm) - set(v_pm))
    only_v = sorted(set(v_pm) - set(o_pm))

    print('=' * 78)
    print(f'节点总数：我方 {len(o_pm)}   厂商 {len(v_pm)}   共有 {len(both)}')
    print('=' * 78)

    # 1) status 不一致
    print('\n### 1. status 不一致（共有节点）\n')
    print(f'{"节点":<46} {"我方":<12} {"厂商":<12}')
    print('-' * 78)
    cnt = 0
    for p in both:
        a = o_pm[p].get('status', '(无)').strip('"')
        b = v_pm[p].get('status', '(无)').strip('"')
        if a != b:
            print(f'{p:<46} {a:<12} {b:<12}')
            cnt += 1
    print(f'合计 {cnt} 处')

    # 2) GPIO 属性不一致
    print('\n### 2. GPIO 属性不一致（共有节点）\n')
    print(f'{"节点":<34} {"属性":<22} {"我方":<20} {"厂商":<20}')
    print('-' * 100)
    cnt = 0
    keys = set(o_gpio) & set(v_gpio)
    for (path, name) in sorted(keys):
        a = o_gpio[(path, name)]
        b = v_gpio[(path, name)]
        sa = ' '.join(pin_name(*x) for x in a)
        sb = ' '.join(pin_name(*x) for x in b)
        if sa != sb:
            print(f'{path:<34} {name:<22} {sa:<20} {sb:<20}')
            cnt += 1
    print(f'合计 {cnt} 处')

    # 3) 单侧存在的 GPIO 节点
    print('\n### 3. 只在单侧出现的 GPIO 属性\n')
    print(f'{"侧":<6} {"节点":<40} {"属性":<22} {"引脚"}')
    print('-' * 100)
    cnt = 0
    for (path, name) in sorted(o_gpio):
        if path not in v_pm:
            sa = ' '.join(pin_name(*x) for x in o_gpio[(path, name)])
            print(f'{"我方":<6} {path:<40} {name:<22} {sa}')
            cnt += 1
    for (path, name) in sorted(v_gpio):
        if path not in o_pm:
            sb = ' '.join(pin_name(*x) for x in v_gpio[(path, name)])
            print(f'{"厂商":<6} {path:<40} {name:<22} {sb}')
            cnt += 1
    print(f'合计 {cnt} 处')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('用法: dts_diff.py <我方.dts> <厂商.dts>')
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
