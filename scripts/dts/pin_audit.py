import re
import sys
from collections import defaultdict

path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/final.dts"
lines = open(path, errors="replace").read().splitlines()

# 1) gpio 控制器别名: gpioN = "/pinctrl/gpio@ADDR"
alias_addr = {}
for ln in lines:
    m = re.match(r'\s*(gpio[0-4])\s*=\s*"/pinctrl/gpio@([0-9a-f]+)";', ln)
    if m:
        alias_addr[m.group(2)] = m.group(1)

# 2) 从 pinctrl 里找出每个 gpio@ADDR 的 phandle
addr_phandle = {}
cur_addr = None
depth = 0
for ln in lines:
    m = re.match(r'^\s*gpio@([0-9a-f]+)\s*\{', ln)
    if m:
        cur_addr = m.group(1)
        addr_phandle.setdefault(cur_addr, None)
        depth = 1
        continue
    if cur_addr and depth:
        pm = re.search(r'phandle = <(0x[0-9a-f]+)>;', ln)
        if pm and addr_phandle.get(cur_addr) is None:
            addr_phandle[cur_addr] = pm.group(1)
        if re.match(r'^\s*\};', ln):
            cur_addr = None
            depth = 0

phandle_gpio = {}
for addr, ph in addr_phandle.items():
    if ph and addr in alias_addr:
        phandle_gpio[ph] = alias_addr[addr]

# 3) 遍历节点，收集 gpio 属性
node_stack = []          # (indent, name)
prop_owner = []          # (gpio_name, pin, node_path, prop)
node_re = re.compile(r'^(\s*)([a-zA-Z0-9_,.+\-]+(?:@[0-9a-f]+)?)\s*\{\s*$')
prop_re = re.compile(r'([a-zA-Z0-9_,.+\-]+)\s*=\s*<([^>]*)>')

for ln in lines:
    nm = node_re.match(ln)
    if nm and not ln.strip().startswith("/*"):
        indent = len(nm.group(1))
        while node_stack and node_stack[-1][0] >= indent:
            node_stack.pop()
        node_stack.append((indent, nm.group(2)))
        continue
    if re.match(r'^\s*\};', ln):
        if node_stack:
            node_stack.pop()
        continue
    pm = prop_re.search(ln)
    if not pm:
        continue
    prop = pm.group(1)
    if "gpio" not in prop:
        continue
    vals = re.findall(r'0x[0-9a-f]+', pm.group(2))
    for i in range(0, len(vals) - 1, 3):
        ph, pin = vals[i], int(vals[i + 1], 16)
        gpio = phandle_gpio.get(ph)
        if not gpio:
            continue
        pathname = "/".join(n for _, n in node_stack)
        prop_owner.append((gpio, pin, pathname, prop))

# 4) 输出按引脚聚合，标出多方占用
by_pin = defaultdict(list)
for gpio, pin, node, prop in prop_owner:
    by_pin[(gpio, pin)].append((node, prop))

print("GPIO 属性占用总数:", len(prop_owner), " 独立引脚:", len(by_pin))
print("=== 同一引脚被多个节点占用 ===")
found = False
for (gpio, pin), users in sorted(by_pin.items()):
    if len({u[0] for u in users}) > 1:
        found = True
        print(f"{gpio} pin{pin}:")
        for node, prop in users:
            print(f"    {prop:22s} <- {node}")
if not found:
    print("(无)")
