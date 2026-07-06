# T9：浇水

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现浇水：选中浇水壶对已翻耕地格按 `use_tool` → 该格标记 `watered=true`，`FarmLayer` 显示为湿耕地（atlas `WATERED=(2,0)`），emit `tile_watered`。为 T10「跨天成长」准备好「当天是否浇水」的数据。

## 需要创建/修改的文件

- 修改 `scripts/autoload/farm_manager.gd`：新增 `water()`，并在 `_on_request_use_item` 分发浇水壶。

## 不要修改的文件

- `event_bus.gd`、其他 autoload、数据类、所有场景、`player.gd`、UI 脚本。

## 实现要求

1. `func water(cell) -> void`：
   - 取 `FarmTile`；要求 `tilled == true`，否则 return（未翻地不能浇）。
   - 已 `watered` 则直接 return（幂等，不重复 emit）。
   - 设 `tile.watered = true`；写回。
   - `_farm.set_cell(cell, TILE_SOURCE_ID, WATERED_ATLAS_COORDS, 0)`（新增常量 `WATERED_ATLAS_COORDS := Vector2i(2,0)`）。
   - emit `tile_watered(cell)`。
2. `_on_request_use_item` 增加分支：`item_id == &"tool_wateringcan"` → `water(cell)`。保留 `tool_hoe`、种子分支。
3. 浇水**不要求**地里有作物（空耕地也可浇，湿润状态照样显示）——保持简单。

## 验收标准

- 翻一格 → 按 `2` 选浇水壶 → 面向该格 `use_tool`：地格变深棕（湿）。
- 未翻耕的地浇水：无效果、不报错。
- 重复浇同一格：无副作用，`tile_watered` 不重复触发。
- 无报错。

## Godot 测试步骤

1. 翻一格。
2. 按 `2` 选浇水壶，`use_tool` → 该格变深棕。
3. 对未翻地格浇水 → 无变化、无报错。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）为 scripts/autoload/farm_manager.gd 增加浇水。

1) 新增常量：const WATERED_ATLAS_COORDS := Vector2i(2, 0)
2) func water(cell:Vector2i)->void:
   - 若 _ground/_farm 未注册则 push_warning 并 return
   - tile=tiles.get(cell)；要求存在且 tile.tilled==true 否则 return
   - 若 tile.watered 已为 true 则 return（幂等）
   - tile.watered=true; tiles[cell]=tile
   - _farm.set_cell(cell, TILE_SOURCE_ID, WATERED_ATLAS_COORDS, 0)
   - EventBus.tile_watered.emit(cell)
3) _on_request_use_item 增加分支：if item_id==&"tool_wateringcan": water(cell); return
   （保留既有 tool_hoe 与种子分支）

约束：只改 farm_manager.gd。不要动 event_bus.gd、其他 autoload、数据类、任何场景、
player.gd、UI 脚本。浇水不要求地里有作物。
完成后：翻地格浇水变深棕，未翻地浇水无效果，重复浇水无副作用，均无报错。
```
