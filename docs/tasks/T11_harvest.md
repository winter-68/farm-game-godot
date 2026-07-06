# T11：收获（产出进背包）+ 睡觉入口收敛

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现收获：面向**成熟**作物按 `interact` → 产出物进背包、清除作物数据与显示、emit `crop_harvested`。同时把「睡觉」从占用 `interact` 改到**独立调试键**，避免与收获冲突（对应 T4 里的 `TODO(T11)`）。

## 需要创建/修改的文件

- 修改 `project.godot`：新增输入动作 `debug_sleep`（默认回车 Enter，键码 4194309）。
- 修改 `scripts/ui/hud.gd`：睡觉触发由 `interact` 改为 `debug_sleep`，删除 `TODO(T11)` 注释。
- 修改 `scripts/world/player.gd`：`interact` 按下 → `EventBus.request_harvest(target_cell)`。
- 修改 `scripts/autoload/farm_manager.gd`：新增 `harvest()`，连接 `request_harvest`。
- 修改 `scripts/world/crop_view.gd`：实现 `_on_crop_harvested()`（移除或重置作物实例）。

## 不要修改的文件

- `event_bus.gd`、`time_manager.gd`、`inventory_manager.gd`（只读调用）、`save_manager.gd`、数据类、`hotbar.gd`、`world.gd`、场景 `.tscn`（除 `project.godot`）。

## 实现要求

1. 输入：`project.godot` 增加 `debug_sleep = Enter`（不动其它动作）。
2. `hud.gd`：`_unhandled_input` 中把 `interact` 改成 `debug_sleep` 触发 `TimeManager.advance_to_next_day()`；移除旧注释。
3. `player.gd`：`_unhandled_input` 增加——`Input.is_action_just_pressed("interact")` 时 `update_target_cell()` 后 `EventBus.request_harvest.emit(target_cell)`。（与 `use_tool` 分支并存）
4. `FarmManager`：
   - `_ready` 增加 `EventBus.request_harvest.connect(_on_request_harvest)`。
   - `func _on_request_harvest(cell): harvest(cell)`
   - `func harvest(cell) -> void`：
     - 取 `tile`；要求存在、`crop_id != &""` 且 `tile.harvestable == true`，否则 return。
     - `crop := ItemDatabase.get_crop(tile.crop_id)`；`InventoryManager.add_item(crop.produce_item_id, crop.produce_amount)`。
     - emit `crop_harvested(cell, crop.produce_item_id, crop.produce_amount)`。
     - **再生 vs 清除**：
       - 若 `crop.regrows`：`tile.stage = crop.regrow_to_stage`；`tile.harvestable = false`；`tile.watered_days = 0`（作物保留，回到较早阶段）。
       - 否则：清空作物——`tile.crop_id = &""`、`tile.stage = 0`、`tile.harvestable = false`、`tile.watered_days = 0`（`tilled` 保持 true）。
5. `crop_view._on_crop_harvested(cell, _produce_id, _amount)`：
   - 若对应 tile 仍有作物（再生情况）：按新 `stage` 刷新显示。
   - 否则：从 `CropsRoot` 移除该实例（`queue_free`）并清掉 `_crops[cell]`、`_crop_ids[cell]`。
   - 简化：可由 `crop_view` 依据 `FarmManager.tiles[cell].crop_id` 是否为空判断走哪条。

## 验收标准

- 作物长到成熟（最大）后，面向它按 `interact` → 作物消失，背包出现产出物（绿豆），数量 +1。
- 未成熟的作物按 `interact` → 不收获、不报错。
- 睡觉改用 **Enter**；`interact` 不再推进天数。
- 无报错。

## Godot 测试步骤

1. 走完整流程把作物养到成熟（种→浇→Enter睡→浇→Enter睡）。
2. 面向成熟作物按 `interact`（空格）→ 作物消失，快捷栏/背包产出物 +1。
3. 对未成熟作物按 `interact` → 无变化、无报错。
4. 确认按 Enter 才睡觉、空格不再睡觉。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现收获，并把睡觉从 interact 改到 debug_sleep。

1) project.godot：新增输入动作 debug_sleep，绑定 Enter（physical_keycode 4194309）。
   不修改其它输入动作。
2) scripts/ui/hud.gd：_unhandled_input 中睡觉判定由 "interact" 改为 "debug_sleep"，
   调 TimeManager.advance_to_next_day()；删除 TODO(T11) 注释。
3) scripts/world/player.gd：_unhandled_input 增加：
   if Input.is_action_just_pressed("interact"):
       update_target_cell(); EventBus.request_harvest.emit(target_cell)
   （保留原 use_tool 分支）
4) scripts/autoload/farm_manager.gd：
   - _ready 增加 EventBus.request_harvest.connect(_on_request_harvest)
   - func _on_request_harvest(cell): harvest(cell)
   - func harvest(cell)->void:
       tile=tiles.get(cell)；要求存在且 crop_id!=&"" 且 tile.harvestable 否则 return
       crop=ItemDatabase.get_crop(tile.crop_id)
       InventoryManager.add_item(crop.produce_item_id, crop.produce_amount)
       EventBus.crop_harvested.emit(cell, crop.produce_item_id, crop.produce_amount)
       if crop.regrows: tile.stage=crop.regrow_to_stage; tile.harvestable=false; tile.watered_days=0
       else: tile.crop_id=&""; tile.stage=0; tile.harvestable=false; tile.watered_days=0
5) scripts/world/crop_view.gd：_on_crop_harvested(cell, _produce_id, _amount):
   查 FarmManager.tiles[cell]，若 crop_id==&"" 或不存在：
     若 _crops.has(cell): _crops[cell].queue_free(); _crops.erase(cell); _crop_ids.erase(cell)
   否则(再生)：_crops[cell].show_stage(ItemDatabase.get_crop(_crop_ids[cell]), tile.stage)

约束：不要修改 event_bus.gd、time_manager.gd、inventory_manager.gd(只读)、save_manager.gd、
数据类、hotbar.gd、world.gd、以及除 project.godot 外的 .tscn 场景。
完成后：成熟作物按 interact 收获、产出物入背包、作物消失；未成熟不收获；睡觉改为 Enter；无报错。
```
