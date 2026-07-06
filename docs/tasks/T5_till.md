# T5：目标瓦片指示 + 翻地（锄头）

> 通用约束见 [../README.md](../README.md)。

## 任务目标

打通「玩家使用工具 → FarmManager 改状态 → FarmLayer 显示」的第一条链路：玩家面前的瓦片高亮为**目标瓦片**；按 `use_tool` 且当前为锄头时，把该瓦片翻成耕地（`FarmManager` 记录状态 + `FarmLayer` 显示棕色 + emit `tile_tilled`）。此阶段先**硬编码当前工具为锄头**（背包 T7 再接）。

## 需要创建/修改的文件

- 创建 `scripts/world/world.gd` 挂到 `World`（若尚无）：`_ready()` 注入图层、`_process()` 移动高亮、把 `GroundLayer` 引用给 Player。
- 修改 `scripts/world/player.gd`：计算 `target_cell`，按 `use_tool` emit `EventBus.request_use_item(&"tool_hoe", target_cell)`。
- 修改 `scenes/world/world.tscn`：加 `TileHighlight`（半透明 `Sprite2D`/`ColorRect`）。
- 修改 `scripts/autoload/farm_manager.gd`：持有 `tiles: Dictionary`、`register_layers()`、`till(cell)`，监听 `request_use_item`。

## 不要修改的文件

- `event_bus.gd`、`time_manager.gd`、`inventory_manager.gd`、`save_manager.gd`、数据类（`farm_tile.gd` 已在 T1 建好，直接用）。

## 实现要求

1. `target_cell = ground_layer.local_to_map(玩家局部坐标) + facing`。Player 需能拿到 `GroundLayer`（由 world 注入）。
2. `TileHighlight` 每帧移到 `target_cell` 对应世界坐标（cell 中心）。
3. `FarmManager` 通过 `world._ready()` 调 `register_layers(ground, farm)` 注入引用，**不主动搜索场景树**。
4. `till(cell)`：若该 cell 尚未 `tilled`（MVP 只要在地面范围即可）→ 新建/更新 `FarmTile.tilled=true`，`farm_layer.set_cell(cell, TILLED atlas=(1,0))`，emit `tile_tilled(cell)`。已耕地重复翻地则忽略。
5. `request_use_item` 分发：`&"tool_hoe"` → `till`；其他 id 暂忽略（留 TODO）。
6. Player 侧当前工具**先硬编码** `&"tool_hoe"`，注释标注 T7 接背包。

## 验收标准

- 玩家面前出现高亮方块，随移动/转向移动。
- 面向一格按 `use_tool`，该格变棕色耕地并保持；重复按不报错、不重复。
- 信号 `tile_tilled` 触发。
- 无报错。

## Godot 测试步骤

1. 运行，移动使高亮落在地面某格。
2. 按 `use_tool`（J/左键）→ 该格变耕地。
3. 走开再回看，耕地状态仍在（内存态）。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3）打通「使用工具→翻地→显示」链路。此步当前工具硬编码为锄头。

1) 创建/使用 scripts/world/world.gd 挂到 World，_ready 中：
   - FarmManager.register_layers(ground_layer, farm_layer)  # 传 GroundLayer 与 FarmLayer
   - 把 ground_layer 引用赋给 Player（供其算 target_cell）
   _process 中把 TileHighlight 移到 target_cell 的世界坐标(cell中心)。
2) scripts/autoload/farm_manager.gd (extends Node)：
   - var tiles: Dictionary = {}          # Vector2i -> FarmTile
   - var _ground: TileMapLayer; var _farm: TileMapLayer
   - func register_layers(ground, farm): 保存引用
   - _ready: EventBus.request_use_item.connect(_on_request_use_item)
   - _on_request_use_item(item_id, cell): 若 item_id==&"tool_hoe" 调 till(cell)；
     其它 id 先忽略并留 TODO 注释
   - func till(cell:Vector2i)->void: 取/建 FarmTile；若未 tilled：tilled=true，
     tiles[cell]=t，_farm.set_cell(cell, Vector2i(1,0)) 显示耕地(TILLED)，
     EventBus.tile_tilled.emit(cell)。已耕则直接返回。
     (atlas 源id用 tileset 默认0；TILLED atlas 坐标=(1,0)，与 T3 约定一致)
3) scripts/world/player.gd 增加：
   - 一个 ground 引用变量（由 world 注入）
   - 计算 target_cell = ground.local_to_map(ground.to_local(global_position)) + facing
   - _unhandled_input: 若 use_tool 刚按下：
       EventBus.request_use_item.emit(&"tool_hoe", target_cell)  # TODO(T7): 换成背包选中项
4) scenes/world/world.tscn 加一个半透明 Sprite2D/ColorRect 名 TileHighlight。

约束：不要修改 event_bus.gd、time_manager.gd、inventory_manager.gd、save_manager.gd 或数据类。
autoload 不直接搜索场景树，图层引用一律通过 register_layers 注入。
运行后：面前有高亮格，按 use_tool 使该格变棕色耕地，重复无副作用，无报错。
```
