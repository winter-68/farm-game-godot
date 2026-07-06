# T8：播种（消耗种子 → 生成作物实例）

> 通用约束见 [../README.md](../README.md)。

## 任务目标

打通播种：选中种子对已翻耕、无作物的地格按 `use_tool` → 消耗 1 颗种子、`FarmManager` 记录作物数据、`CropsRoot` 视图生成一株占位作物（阶段 0）。**数据在 FarmManager，显示在 CropsRoot 视图脚本**，严守分离。

## 需要创建/修改的文件

- 创建 `scenes/world/farm/crop.tscn` + `scripts/world/crop.gd`（单株作物显示）。
- 创建 `scripts/world/crop_view.gd`（挂到 `world.tscn` 的 `CropsRoot`）：监听作物信号，增删/更新作物实例。
- 修改 `scenes/world/world.tscn`：给 `CropsRoot` 挂 `crop_view.gd`。
- 修改 `scripts/world/world.gd`：把 `ground_layer` 注入 `crop_view`（供定位）。
- 修改 `scripts/autoload/farm_manager.gd`：新增 `plant()`，并在 `_on_request_use_item` 分发种子。

## 不要修改的文件

- `event_bus.gd`、`time_manager.gd`、`inventory_manager.gd`（只读调用）、`save_manager.gd`、数据类、`player.gd`、`hud.gd`、`hotbar.gd`。

## 实现要求

1. `crop.gd`（`Node2D`，含子 `Sprite2D`）：
   - `func show_stage(crop_data: CropData, stage: int)`：若 `crop_data.stage_textures[stage]` 非空则用之；**为空时用占位**——`Sprite2D` 给一个 `PlaceholderTexture2D`，用 `modulate`（绿）+ `scale`（随 stage 增大，如 `0.4 + 0.3*stage`）体现成长差异。
2. `crop_view.gd`（挂 `CropsRoot`）：
   - `var _ground: TileMapLayer`；`func register_ground(g)`。
   - `var _crops: Dictionary = {}`（`Vector2i → crop 实例`）。
   - `_ready` 连接 `EventBus.crop_planted`、`crop_grew`、`crop_harvested`。
   - `crop_planted(cell, crop_id)`：实例化 `crop.tscn`，`position = _ground.map_to_local(cell)`，`show_stage(CropData, 0)`，加入 `CropsRoot` 与 `_crops`。
   - `crop_grew`、`crop_harvested` 先留空实现（各写 TODO，T10/T11 填）。
3. `world.gd._ready()`：`$CropsRoot.register_ground(ground_layer)`（在 `FarmManager.register_layers` 之后）。
4. `FarmManager`：
   - `func plant(cell, seed_item_id) -> void`：
     - 取 `FarmTile`；要求 `tilled == true` 且 `crop_id == &""`，否则 return。
     - `seed := ItemDatabase.get_item(seed_item_id)`；要求 `type == SEED` 且 `linked_crop_id` 对应的 `CropData` 存在，否则 return。
     - `InventoryManager.remove_item(seed_item_id, 1)` 失败则 return。
     - 设 `tile.crop_id = seed.linked_crop_id`、`stage = 0`、`watered_days = 0`、`harvestable = false`；写回 `tiles`。
     - emit `crop_planted(cell, tile.crop_id)`。
   - `_on_request_use_item` 增加分支：`seed := ItemDatabase.get_item(item_id)`，若 `seed != null and seed.type == ItemData.Type.SEED` → `plant(cell, item_id)`。保留既有 `tool_hoe` 分支。

## 验收标准

- 翻一格 → 切到种子（按 `3`）→ 面向该格按 `use_tool`：出现一株小绿色占位作物，种子数量 10→9。
- 未翻耕的地、或已有作物的地：播种无效果、不报错、不扣种子。
- 无报错。

## Godot 测试步骤

1. 选锄头翻一格。
2. 按 `3` 选种子，面向该格 `use_tool` → 见小方块作物，快捷栏种子 10→9。
3. 对未翻地/已有作物的格再播种 → 无变化、无报错。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现播种，遵守"数据在 FarmManager、显示在 CropsRoot 视图"。

1) scenes/world/farm/crop.tscn（Node2D 名 Crop + 子 Sprite2D）+ scripts/world/crop.gd：
   func show_stage(crop_data: CropData, stage: int):
     若 crop_data.stage_textures 中该 stage 贴图非空则用之；
     否则用 PlaceholderTexture2D 占位，modulate 设绿色，scale=Vector2.ONE*(0.4+0.3*stage)
     以体现成长差异。
2) scripts/world/crop_view.gd（将挂到 CropsRoot, Node2D）：
   var _ground: TileMapLayer; var _crops := {}   # Vector2i->Crop 实例
   func register_ground(g): _ground=g
   _ready: 连接 EventBus.crop_planted/crop_grew/crop_harvested
   _on_crop_planted(cell, crop_id): 实例化 crop.tscn，position=_ground.map_to_local(cell)，
     show_stage(ItemDatabase.get_crop(crop_id),0)，add_child 到自身并存入 _crops[cell]
   _on_crop_grew / _on_crop_harvested: 先留空+TODO(T10)/TODO(T11)
3) scenes/world/world.tscn：给 CropsRoot 挂 crop_view.gd。
4) scripts/world/world.gd._ready：在 register_layers 之后调用 $CropsRoot.register_ground(ground_layer)。
5) scripts/autoload/farm_manager.gd：
   func plant(cell, seed_item_id)->void:
     取/建 FarmTile；要求 tilled 且 crop_id==&"" 否则 return
     seed=ItemDatabase.get_item(seed_item_id)；要求存在且 type==SEED 且
       ItemDatabase.get_crop(seed.linked_crop_id)!=null 否则 return
     若 InventoryManager.remove_item(seed_item_id,1)==false 则 return
     tile.crop_id=seed.linked_crop_id; tile.stage=0; tile.watered_days=0;
       tile.harvestable=false; tiles[cell]=tile
     EventBus.crop_planted.emit(cell, tile.crop_id)
   _on_request_use_item 增加：seed=ItemDatabase.get_item(item_id)；
     if seed and seed.type==ItemData.Type.SEED: plant(cell,item_id)（保留 tool_hoe 分支）

约束：不要修改 event_bus.gd、time_manager.gd、inventory_manager.gd(只读调用)、
save_manager.gd、数据类、player.gd、hud.gd、hotbar.gd。
完成后：翻地→选种子→use_tool 生成占位作物且种子-1；非法格播种无效果不报错。
```
