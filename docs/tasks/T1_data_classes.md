# T1：数据类骨架 + ItemDatabase 资源加载

> 通用约束见 [../README.md](../README.md)。

## 任务目标

定义 `ItemData`、`CropData`、`FarmTile` 三个数据类；让 `ItemDatabase` 在启动时扫描 `resources/items/` 与 `resources/crops/`，加载为字典并提供查询 API；创建占位 `.tres` 资源用于验证。

## 需要创建/修改的文件

- 创建 `scripts/data/item_data.gd`、`scripts/data/crop_data.gd`、`scripts/data/farm_tile.gd`（按 TECH_DESIGN 第 8 节定义，含 `to_dict/from_dict`）。
- 修改 `scripts/autoload/item_database.gd`：实现加载与 `get_item/get_crop/get_all_items`。
- 创建占位资源：`resources/items/seed_greenbean.tres`、`resources/items/produce_greenbean.tres`、`resources/items/tool_hoe.tres`、`resources/items/tool_wateringcan.tres`、`resources/crops/crop_greenbean.tres`。

## 不要修改的文件

- `scripts/autoload/event_bus.gd` 及其他管理器脚本（除 `item_database.gd`）。
- `scenes/` 下任何场景。

## 实现要求

1. 三个数据类用 `class_name` 暴露（`ItemData`/`CropData`/`FarmTile`），字段严格按 TECH_DESIGN 第 8 节。
2. `ItemDatabase._ready()` 遍历目录加载 `.tres`，按 `item_id`/`crop_id` 存入 `Dictionary`；打印 `"[ItemDatabase] loaded N items, M crops"`。
3. 加载失败/重复 id 要 `push_warning`，不崩溃。
4. 占位资源字段填合理值：`seed_greenbean` buy_price=20、linked_crop_id=`crop_greenbean`；`produce_greenbean` sell_price=35；`crop_greenbean` days_per_stage=1、`stage_textures` 放 3 个 `null` 占位表示 3 阶段。`stage_textures` 允许为空/占位。

## 验收标准

- 运行后控制台打印正确的物品数与作物数（≥4 items，≥1 crop）。
- `ItemDatabase.get_item(&"seed_greenbean")` 返回非空且 `linked_crop_id == &"crop_greenbean"`。
- 无报错、无因空贴图导致的崩溃。

## Godot 测试步骤

1. 运行，查看输出面板加载数量。
2. 用 Remote 调试台执行 `ItemDatabase.get_item(&"seed_greenbean").display_name` 验证（或临时在 `game_manager.gd` 加打印，验证后删除）。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3, GDScript）中实现数据层与资源加载。

1) 创建 scripts/data/item_data.gd：class_name ItemData extends Resource，字段：
   item_id:StringName, display_name:String, type(枚举 SEED/PRODUCE/TOOL/MISC),
   icon:Texture2D, buy_price:int, sell_price:int, stackable:bool=true,
   max_stack:int=99, linked_crop_id:StringName。全部 @export。
2) 创建 scripts/data/crop_data.gd：class_name CropData extends Resource，字段：
   crop_id:StringName, display_name:String, produce_item_id:StringName,
   days_per_stage:int=1, stage_textures:Array[Texture2D], regrows:bool=false,
   regrow_to_stage:int=0, produce_amount:int=1。加方法 mature_stage()->int
   返回 stage_textures.size()-1。
3) 创建 scripts/data/farm_tile.gd：class_name FarmTile extends RefCounted，字段：
   tilled/watered:bool, crop_id:StringName, stage:int, watered_days:int,
   harvestable:bool。实现 to_dict()->Dictionary 与 static from_dict(d)->FarmTile。
4) 修改 scripts/autoload/item_database.gd：_ready() 用 DirAccess 遍历
   res://resources/items 与 res://resources/crops，load 每个 .tres，
   按 id 存入两个 Dictionary。提供 get_item(id)->ItemData、get_crop(id)->CropData、
   get_all_items()->Array。重复或无效 id 用 push_warning。最后
   print("[ItemDatabase] loaded %d items, %d crops" % [...])。
5) 创建占位资源（.tres）：
   - resources/items/tool_hoe.tres (TOOL, 不可买卖)
   - resources/items/tool_wateringcan.tres (TOOL)
   - resources/items/seed_greenbean.tres (SEED, buy_price=20, linked_crop_id=crop_greenbean)
   - resources/items/produce_greenbean.tres (PRODUCE, sell_price=35)
   - resources/crops/crop_greenbean.tres (produce_item_id=produce_greenbean,
     days_per_stage=1, stage_textures 放 3 个 null 占位)

约束：不要修改 event_bus.gd 或其它管理器；不要动 scenes/。占位贴图允许为 null，
代码要能容忍空贴图不崩溃。完成后运行应打印正确的加载数量且无报错。
```
