# 09 · 鼠标光标问题调查

> **结论**：真实根因是 **WindowManager 给 MMI 的显示信息漏填 RS 屏幕 ID**，光标被创建在没有画面的
> RS 屏幕 0 上；桌面窗口走另一条正确映射的挂载路径，所以「看不到光标但点击有效」。
> 修正库 `libwms.z.so` 已编译通过（SHA256 `c7055481…`），**尚未上板验收**。
> 硬件光标在本板不可用（厂商 VDI 未实现），当前始终走软件光标。

## 1. 起点：一个建立在错误前提上的结论

早期记录「光标冻结在屏幕左上角」**不成立**：排查期间鼠标一直插在操作者 Windows 主机上，从未接到开发板。

```
# /proc/bus/input/devices      → 只有 bt-powerkey / pwrkey / headset-keys / es8388 / adc-keys / hdmi0 / hdmi1
# ls /dev/input/               → event0 ~ event6，全部是按键 / 耳机 / HDMI-CEC
```

USB 总线树只有根 hub，无下游设备。**没有指针设备时 MMI 不会创建 `CURSOR_NODE`**，
不能从画面推断光标状态。左上角那个对象至今未定性，与鼠标光标是两件事。

## 2. 真实现象（接上显示器 + USB 鼠标后）

| 端口 | 现象 |
| --- | --- |
| HDMI OUT1 | **看不到光标**，但点击有效、UI 有 hover 效果 |
| HDMI OUT0 | 光标可见 |

两次观察都发生在任何补丁库安装之前，所以这是**基线缺陷**，不是改坏的。

真实鼠标证据：

```
N: Name="PixArt Dell MS116 USB Optical Mouse"
I: Bus=0003 Vendor=413c Product=301a Version=0111
H: Handlers=event7 dmcfreq
B: REL=903
```

路径 `usbdrd3_1/fc400000.usb/.../usb3/3-1`，接口 `DRIVER=usbhid`，可读写 `3/1/2`；
`multimodalinput`（PID 321）已通过 fd 31 打开 `/dev/input/event7`。
MMI 日志在操作鼠标时连续出现：

```
MouseTransformProcessor: [|176]No display
MouseTransformProcessor: [|524]No display
InputKeyFlow: PixArt Dell MS116 USB Optical Mouse, ...
```

源码对照：176 行是移动处理、524 行是按下处理，两处都在
`WIN_MGR->GetCursorPos().displayId < 0` 时提前返回 —— 事件已进入 MMI，阻断发生在**取得有效显示目标**这一步。

`usb_host` 的 SIGSEGV 在同一轮里也出现了，但鼠标注册、MMI 打开 event7、鼠标事件都已成功，
说明该服务崩溃**没有**阻断 HID 输入链路。

## 3. 根因链路

1. 经典 WindowManager 的 `InputWindowMonitor::UpdateDisplayInfo()` 构造 `MMI::DisplayInfo` 时
   **漏填 `rsId`**，该聚合字段被值初始化为 **0**。
2. MMI 原样消费 `rsId` 并 `AttachToDisplay(rsId)` → 光标 surface 挂到 **RS 屏幕 0**。
3. 实际有画面的输出是 **RS 屏幕 1**（HDMI OUT1）。
4. 桌面窗口走另一条经过正确映射的挂载路径，鼠标事件的逻辑坐标仍然有效 → 点击和 hover 正常。
5. 切到 HDMI OUT0（对应 RS 屏幕 0）时恰好掩盖了映射遗漏。

> 因此不能把「丝印 HDMI 编号」当作 RS ID：两者不是一回事。

## 4. 修正（已编译，未上板）

文件：`foundation/window/window_manager/wmserver/src/input_window_monitor.cpp`

- 用 `GetScreenInfoByDisplayId()` 查询真实屏幕，填入 `GetRsId()`；
- `screenArea` 与 `ScreenInfo` 使用一致的物理屏幕 ID；
- 屏幕结构体改为值初始化；
- 窗口信息补填 `displayId`，消除已定位的 `physical(-1)` 来源；
- **没有有效 RS 屏幕时不发布该条显示信息**；
- 相应无效屏幕单元测试断言调整。

产物：`libwms.z.so`，SHA256 `c7055481c6e72aeedaa39a487af6e6b5f8b84fe5d73090c212e38213db7d56ab`。
源码补丁见 `scripts/board/cursor-screen-id.patch`，改前文件 `input_window_monitor.cpp.orig`，
单元测试源 `input_window_monitor_test.cpp` 编译通过（测试二进制未执行）。

安装方式：串口分块传输 + 校验，临时 `bind mount` 到原库路径并受控重启桌面服务，
**不要直接覆盖系统分区**（重启即失效）。见 [06-onboard-debug.md](06-onboard-debug.md) 第 8 节。

## 5. 被推翻的旧补丁（`MoveSoft`）

早期补丁基于「`RSPointerWindowManager::SetHwcNodeBounds()` 只记录边界、不移动节点」这一读码结论，
把非镜像模式改成 `surfaceNode_->SetBounds(...)`。

复核确认该结论**错误**——只读了写入端，漏了消费端：

| 阶段 | 文件:行 | 实际行为 |
| --- | --- | --- |
| 接口入口 | `rs_client_to_render_connection.cpp:612-631` | 有虚拟屏或 `GetIsPointerEnableHwc()` 为 false 时禁止光标跳帧并请求下次 VSync，随后记录新边界 |
| 暂存 | `rs_pointer_window_manager.cpp:112-123` | 保存节点 ID、位置、尺寸，标记边界更新 |
| 帧内消费 | 同文件 `:61-109`（关键 `:84-89`） | `UpdatePointerInfo()` 对渲染节点 `properties.SetBounds(...)`、`node->SetDirty()`、加入待同步列表 |
| 调用时机 | `rs_main_thread.cpp:2273-2292` | 需要遍历节点树的帧里先 `UpdatePointerInfo()` 再 `rootNode->QuickPrepare(...)` |

即：渲染节点边界更新**不受** `UpdateHwcNodeLayerInfo(..., isPointerEnableHwc_)` 布尔值限制，
上游「非镜像只调 `SetHwcNodeBounds`」的设计是成立的。

旧补丁保留原状（避免同时改变多个因素），但只能作为**未验证的行为变更**，不能称为修复。
它用 `static const bool useHwcCursorBounds = GetParameter("persist.multimodalinput.cursor.hwcbounds", "0") == "1"`
做开关；由于是 `static const`，同一进程内直接改参数不构成有效 A/B，必须重启进程。

## 6. 硬件光标为什么不可用

| 层 | 事实 |
| --- | --- |
| MMI | `HardwareCursorPointerManager::IsSupported()` 调 `GetDisplayProperty(devId, DISPLAY_CAPBILITY_HARDWARE_CURSOR, value)`；`SetPosition()` 调 `UpdateHardwareCursor(devId, x, y, buffer)` |
| 厂商 VDI | `device/soc/rockchip/hardware/display/src/display_device/display_composer_vdi_impl.cpp:114` 的 `GetDisplayProperty` 是**无条件桩**，恒返回 `HDF_ERR_NOT_SUPPORT`；该文件里 grep `Cursor` 无任何匹配 |
| 构建产物 | `libdisplay_composer_vdi_impl.z.so` 中 `UpdateHardwareCursor` **未导出**；全树只存在于单元测试与 fuzz 用例，无产品实现 |
| DRM 合成 | `hdi_drm_composition.cpp` / `drm_display.cpp` / `drm_crtc.cpp` 无光标平面绑定逻辑；`drm_plane.cpp:136` 只把 `DRM_PLANE_TYPE_CURSOR` 解析成 `mType` |
| 内核 | `rockchip_drm_vop2.c` 有 `vop2_cursor_plane_init()` 与 `legacy_cursor_update`，**能力具备** |

结论：`GetHardCursorEnabled()` 恒为 false，始终走 `MoveSoft()`。
启用硬件光标需要补 `GetDisplayProperty`、实现并导出 `UpdateHardwareCursor`、在 DRM 合成路径绑定光标平面
——**子系统级工作量，不是补丁级**。

另外 `hdi_gfx_composition.cpp:112-122` 在按合成类型 `SetDeviceSelect(...)` 之后无条件
`layer->SetDeviceSelect(COMPOSITION_CLIENT);`，使上面的分支完全失效（对 GFX 合成结果等价，
但属明显调试残留，说明该路径的光标层从未被真正验证）。

## 7. 明确的误判清单（不要继承）

1. 「光标冻结在左上角」——板上从未接过鼠标，现象从未被观察到。
2. 「切到 PC / 2in1 形态需要 SceneBoard」——错，经典 `WindowManagerService::LoadWindowParameter()`
   读同名参数即可切换。
3. 「自由浮动窗口需要额外开启」——错，`window_node_container.cpp:83` 的
   `WindowLayoutMode::CASCADE` 就是默认布局策略。
4. 「填 `GetDisplayProperty` 桩即可启用硬件光标」——严重低估，见第 6 节。
5. 「`SetHwcNodeBounds` 只记录边界、不移动节点」——错，见第 5 节。
6. 「没新增 eventN 就一定是 USB 枚举问题」——只能说明预期设备未注册，需区分枚举 / 供电 / HID 绑定 /
   输入设备注册 / evdev 多个阶段。

## 8. 下一步验证步骤

1. 恢复串口通信，用 `Send-BoardCursorReliable.ps1` 传新库并核对 SHA256。
2. 先临时 `bind mount` 到原库路径，受控重启桌面服务（不改系统分区）。
3. **在 HDMI OUT1 复现原问题**，加载新库后检查 `cursor-screen-ids` 相关日志与用户看到的光标/移动/点击/hover；
   然后复测 HDMI OUT0，避免只验证本来正常的端口。
4. 通过后才纳入正式镜像；board 重启后 bind mount 失效，需明确说明。
5. 仍未验证：左上角原对象身份、旧 `MoveSoft` 补丁有效性、双 HDMI 同时输出、热插拔稳定性。

取证材料：`evidence/`（`serial-usb-probe-1.txt`、`mmi-enumeration.*`、`display-state-2.*`、
`usb-hid-confirm.*`、`cursor-screen-ids.*`、`mouse-with-display-mmi.*`、`source-screen-id-review.txt`、
`build-library.log` 等）。
