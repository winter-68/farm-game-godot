# T10：作物跨天成长

> 通用约束见 [../README.md](../README.md)。

## 任务目标

让作物随天数成长：跨天（`day_passed`）时，前一天**已浇水**的有作物地格累计成长、按 `days_per_stage` 推进 `stage`，达到成熟阶段标记 `harvestable`；同时**重置当天浇水状态**（湿耕地视觉回到普通耕地）。作物视图随 `crop_grew` 更新贴图/大小。

## 需要创建/修改的文件

- 修改 `scripts/autoload/farm_manager.gd`：连接 `day_passed`，实现 `_on_day_passed()` 成长与浇水重置逻辑。
- 修改 `scripts/world/crop_view.gd`：实现 `_on_crop_grew()`（更新对应作物实例的显示）。

## 不要修改的文件

- `event_bus.gd`、`time_manager.gd`、`inventory_manager.gd`、`save_manager.gd`、数据类、`player.gd`、`hud.gd`、`hotbar.gd`、场景文件。

## 实现要求

1. `FarmManager._ready()` 增加：`EventBus.day_passed.connect(_on_day_passed)`。
2. `func _on_day_passed(_new_day) -> void`：遍历 `tiles` 每个 `cell/tile`：
   - **先处理成长**：若 `tile.crop_id != &""` 且 `tile.watered` 且未成熟：
     - `crop := ItemDatabase.get_crop(tile.crop_id)`
     - `tile.watered_days += 1`
     - 当 `tile.watered_days >= crop.days_per_stage` 且 `tile.stage < crop.mature_stage()`：`tile.stage += 1`；`tile.watered_days = 0`；emit `crop_grew(cell, tile.stage)`；若 `tile.stage == crop.mature_stage()` 则 `tile.harvestable = true`。
   - **再重置浇水**：若 `tile.watered`：`tile.watered = false`；若该格仍是耕地，`_farm.set_cell(cell, TILE_SOURCE_ID, TILLED_ATLAS_COORDS, 0)`（湿→普通耕地视觉）。
   - 顺序很重要：**先用「昨天浇的水」推进成长，再清空浇水**。
3. `crop_view._on_crop_grew(cell, stage)`：取 `_crops[cell]` 实例，调 `show_stage(ItemDatabase.get_crop(tile 的 crop_id), stage)`。
   - crop_id 可由 `crop_view` 自己缓存（种植时存 `cell → crop_id`），或从实例上记住；实现时二选一，保持简单。

> 说明：绿豆 `days_per_stage=1`、3 阶段（0/1/2），所以「浇水→睡觉」每次推进一阶，睡 2 次到成熟。

## 验收标准

- 种下作物（阶段 0，小）→ 浇水 → 睡觉：作物变大（阶段 1），且该格湿耕地视觉恢复为普通耕地。
- 再浇水 → 睡觉：到阶段 2（成熟，最大），此后再睡不再变大。
- **不浇水就睡觉**：作物不生长。
- 无报错。

## Godot 测试步骤

1. 翻地→种子→播种（小方块）。
2. 选浇水壶浇水（变深棕）→ 空格睡觉 → 作物变大、地格恢复普通耕地色。
3. 再浇水→睡觉 → 到最大后不再变化。
4. 试一次「不浇水睡觉」→ 作物不长。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现作物跨天成长。

1) scripts/autoload/farm_manager.gd：
   - _ready 增加 EventBus.day_passed.connect(_on_day_passed)
   - func _on_day_passed(_new_day:int)->void: 遍历 tiles 的每个 cell,tile：
       # 先成长（用昨天浇的水）
       if tile.crop_id != &"" and tile.watered:
         var crop = ItemDatabase.get_crop(tile.crop_id)
         if crop and tile.stage < crop.mature_stage():
           tile.watered_days += 1
           if tile.watered_days >= crop.days_per_stage:
             tile.stage += 1; tile.watered_days = 0
             EventBus.crop_grew.emit(cell, tile.stage)
             if tile.stage == crop.mature_stage(): tile.harvestable = true
       # 再重置浇水视觉
       if tile.watered:
         tile.watered = false
         if tile.tilled:
           _farm.set_cell(cell, TILE_SOURCE_ID, TILLED_ATLAS_COORDS, 0)
2) scripts/world/crop_view.gd：
   - 种植时缓存 cell->crop_id（例如另建 _crop_ids 字典，在 _on_crop_planted 里存）
   - _on_crop_grew(cell, stage): 若 _crops.has(cell)：
       _crops[cell].show_stage(ItemDatabase.get_crop(_crop_ids[cell]), stage)

约束：不要修改 event_bus.gd、time_manager.gd、inventory_manager.gd、save_manager.gd、
数据类、player.gd、hud.gd、hotbar.gd、场景文件。
遍历字典时不要在循环内增删 tiles 的键。
完成后：浇水后睡觉作物长大且地格恢复普通耕地色，不浇水不长，成熟后不再变大，无报错。
```
