# T7：快捷栏 Hotbar UI + 选中项（替换硬编码锄头）

> 通用约束见 [../README.md](../README.md)。

## 任务目标

创建快捷栏 UI：显示背包前 10 个槽，高亮当前选中槽，数字键 `1~0` 切换选中。同时把 Player 的「使用工具」从**硬编码锄头**改为**读取当前选中项**——打通「选什么，用什么」。

## 需要创建/修改的文件

- 创建 `scenes/ui/hotbar.tscn` + `scripts/ui/hotbar.gd`。
- 修改 `scenes/main/main.tscn`：在 `UI`(CanvasLayer) 下实例化 `hotbar.tscn`。
- 修改 `scripts/world/player.gd`：`use_tool` 时改用 `InventoryManager.get_selected_item_id()`。

## 不要修改的文件

- `event_bus.gd`、autoload（除**不改** InventoryManager，仅调用它）、数据类、`world.tscn`、`hud.gd`、`farm_manager.gd`。

> 说明：本任务**只读**调用 `InventoryManager`，不修改其脚本。

## 实现要求

1. `hotbar.tscn`：`Control` 根 + `HBoxContainer`，含 10 个格子（每格：背景 + 物品名/数量 `Label` 占位，无图标也行）。对应背包槽 `0..9`。
2. `hotbar.gd`：
   - `_ready()` 连接 `EventBus.inventory_changed` 与 `selected_slot_changed`，并立即刷新一次。
   - 刷新：遍历前 10 槽，显示 `item_id` 简称与数量（空槽留白）；选中槽高亮（如边框/背景色）。
   - `_unhandled_input`：按下 `hotbar_1..hotbar_0` → `InventoryManager.set_selected(对应 index)`（`hotbar_1`→0 … `hotbar_0`→9）。
3. `player.gd` 修改 `use_tool` 分支：
   - 取 `var item_id := InventoryManager.get_selected_item_id()`
   - 若 `item_id == &""` 直接 return（空手不操作）
   - `EventBus.request_use_item.emit(item_id, target_cell)`
   - 删除原 `&"tool_hoe"` 硬编码与 `// TODO(T7)` 注释。

## 验收标准

- HUD 下方出现快捷栏，10 格，槽 0=锄头、槽 1=浇水壶、槽 2=绿豆种子×10。
- 按 `1/2/3` 高亮随之切换。
- 选中槽 0（锄头）时按 `use_tool` 仍能翻地；选中槽 2（种子）时按 `use_tool` **暂时无效果**（播种在 T8 实现，但**不应报错**）。
- 无报错。

## Godot 测试步骤

1. F5，看快捷栏三格有内容、其余留白，槽 0 默认高亮。
2. 按 `1/2/3` 切换高亮。
3. 选锄头翻地正常；选种子按 use_tool 无效果且无报错。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现快捷栏并接入玩家选中项。

1) scenes/ui/hotbar.tscn：Control 根，内含 HBoxContainer，10 个格子控件，
   每格含背景 Panel/ColorRect + 一个 Label（显示物品简称与数量）。对应背包槽 0..9。
2) scripts/ui/hotbar.gd（挂 Control 根）：
   - _ready: 连接 EventBus.inventory_changed 和 EventBus.selected_slot_changed，立即刷新一次
   - 刷新函数：读 InventoryManager.slots 前10个，Label 显示 item_id 简称+数量(空槽留白)；
     选中槽(InventoryManager.selected_index)高亮(改背景色或显示边框)
   - _unhandled_input: hotbar_1..hotbar_0 分别 InventoryManager.set_selected(0..9)
3) 修改 scenes/main/main.tscn：在 UI(CanvasLayer) 下实例化 hotbar.tscn（放屏幕底部）。
4) 修改 scripts/world/player.gd 的 use_tool 分支：
   var item_id := InventoryManager.get_selected_item_id()
   if item_id == &"": return
   update_target_cell()
   EventBus.request_use_item.emit(item_id, target_cell)
   （删除原 &"tool_hoe" 硬编码和 TODO(T7) 注释）

约束：只读调用 InventoryManager，不修改其脚本；不要改 event_bus.gd、farm_manager.gd、
其他 autoload、数据类、world.tscn、hud.gd。
完成后：快捷栏显示三格内容，1/2/3 切换高亮，选锄头能翻地，选种子按 use_tool 无效果也不报错。
```
