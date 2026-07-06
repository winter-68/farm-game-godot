# T16：读取存档并重建世界/UI

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现读档：读 `slot_0.json`，把数据灌回 Time/Inventory/Farm 各管理器与玩家位置，emit `game_loaded`；`FarmManager` 重画农田瓦片，`CropView` 依数据重建作物实例，HUD/Hotbar 靠既有信号自动刷新。加调试键 `debug_load` 触发。

## 需要创建/修改的文件

- 修改 `scripts/autoload/save_manager.gd`：新增 `load_game(slot) -> bool`。
- 修改 `scripts/autoload/farm_manager.gd`：新增 `load_from_dict(d)`（清空+重建 tiles，重画 FarmLayer）。
- 修改 `scripts/autoload/game_manager.gd`：`set_player_position()`，监听 `debug_load`。
- 修改 `scripts/world/crop_view.gd`：监听 `game_loaded` → 重建所有作物实例。
- 修改 `project.godot`：新增输入动作 `debug_load`（默认 `L`，键码 76）。

## 不要修改的文件

- `event_bus.gd`、`time_manager.gd`、`inventory_manager.gd`（已有 `load_from_dict`，只调用）、数据类、其他 UI 脚本、`player.gd`、`world.gd`、除 `project.godot` 外的场景。

## 实现要求

1. `FarmManager.load_from_dict(d)`：
   - 先清空旧显示：遍历现有 `tiles.keys()`，`if _farm: _farm.erase_cell(cell)`；再 `tiles.clear()`。
   - 遍历 `d.get("tiles", {})`：键 `"x,y"` 用 `split(",")` 还原 `Vector2i`；`FarmTile.from_dict(v)` 建 tile 存入 `tiles`。
   - 重画：`if _farm and tile.tilled`：`_farm.set_cell(cell, TILE_SOURCE_ID, WATERED_ATLAS_COORDS if tile.watered else TILLED_ATLAS_COORDS, 0)`。
2. `GameManager`：
   - `func set_player_position(pos: Vector2)`：`if _player: _player.global_position = pos`
   - `_unhandled_input` 增加：`debug_load` → `SaveManager.load_game(0)`
3. `SaveManager.load_game(slot) -> bool`：
   - 不存在返回 false；读文件 → `JSON.parse_string`；解析失败 `push_warning` 返回 false。
   - **顺序**：`TimeManager.load_from_dict(data.time)` → `InventoryManager.load_from_dict(data.inventory)` → `FarmManager.load_from_dict(data.farm)` → `GameManager.set_player_position(...)` → **最后** `EventBus.game_loaded.emit(slot)`。
   - `print("[SaveManager] loaded slot %d" % slot)`；返回 true。
4. `CropView`：
   - `_ready` 增加 `EventBus.game_loaded.connect(_on_game_loaded)`。
   - `_on_game_loaded(_slot)`：清掉现有实例（`_crops` 全部 `queue_free`，清 `_crops/_crop_ids`）→ 若 `_ground==null` 返回 → 遍历 `FarmManager.tiles`，对 `crop_id != &""` 的格实例化 crop、定位、`show_stage(crop_data, tile.stage)`，写回 `_crops/_crop_ids`。

> 顺序关键：`game_loaded` 必须在 `FarmManager.load_from_dict` **之后**发，否则 CropView 读到的是旧 tiles。

## 验收标准

- 玩几步（翻地、种作物到某阶段、赚钱、移动）→ 按 **K** 存档。
- 继续乱改状态（再翻地、花钱、走开）→ 按 **L** 读档：
  - HUD 天数/金币、背包、农田耕地/湿润、作物及其阶段、玩家位置**全部回到存档时刻**。
- 存档不存在时按 L：不报错（返回 false）。
- 无报错。

## Godot 测试步骤

1. 操作若干 → K 存档。
2. 再乱改 → L 读档 → 核对全部状态回滚（尤其作物阶段与农田湿润显示）。
3. 删掉存档或换槽位测 L → 无崩溃。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现读档与世界重建。

1) project.godot：新增输入动作 debug_load 绑定 L（physical_keycode 76）。不改其它。
2) scripts/autoload/farm_manager.gd 新增：
   func load_from_dict(d:Dictionary)->void:
     for cell in tiles.keys():
       if _farm: _farm.erase_cell(cell)
     tiles.clear()
     var t:Dictionary = d.get("tiles", {})
     for key in t.keys():
       var parts:PackedStringArray = String(key).split(",")
       if parts.size()!=2: continue
       var cell := Vector2i(int(parts[0]), int(parts[1]))
       var tile := FarmTile.from_dict(t[key])
       tiles[cell]=tile
       if _farm and tile.tilled:
         var atlas := WATERED_ATLAS_COORDS if tile.watered else TILLED_ATLAS_COORDS
         _farm.set_cell(cell, TILE_SOURCE_ID, atlas, 0)
3) scripts/autoload/game_manager.gd：
   func set_player_position(pos:Vector2)->void: if _player: _player.global_position=pos
   _unhandled_input 增加: if Input.is_action_just_pressed("debug_load"): SaveManager.load_game(0)
4) scripts/autoload/save_manager.gd：
   func load_game(slot:int)->bool:
     if not has_save(slot): return false
     var f := FileAccess.open(_slot_path(slot), FileAccess.READ)
     if f==null: return false
     var text := f.get_as_text(); f.close()
     var data = JSON.parse_string(text)
     if typeof(data)!=TYPE_DICTIONARY: push_warning("[SaveManager] bad save"); return false
     TimeManager.load_from_dict(data.get("time",{}))
     InventoryManager.load_from_dict(data.get("inventory",{}))
     FarmManager.load_from_dict(data.get("farm",{}))
     var p:Dictionary = data.get("player",{})
     GameManager.set_player_position(Vector2(p.get("pos_x",0.0), p.get("pos_y",0.0)))
     EventBus.game_loaded.emit(slot)
     print("[SaveManager] loaded slot %d" % slot)
     return true
5) scripts/world/crop_view.gd：
   _ready 增加 EventBus.game_loaded.connect(_on_game_loaded)
   func _on_game_loaded(_slot):
     for c in _crops.keys(): _crops[c].queue_free()
     _crops.clear(); _crop_ids.clear()
     if _ground==null: return
     for cell in FarmManager.tiles.keys():
       var tile = FarmManager.tiles[cell]
       if tile.crop_id==&"": continue
       var cd = ItemDatabase.get_crop(tile.crop_id)
       if cd==null: continue
       var crop = CROP_SCENE.instantiate(); add_child(crop)
       crop.position=_ground.map_to_local(cell); crop.show_stage(cd, tile.stage)
       _crops[cell]=crop; _crop_ids[cell]=tile.crop_id

约束：不要修改 event_bus.gd、time_manager.gd、inventory_manager.gd(只调用 load_from_dict)、
数据类、其他 UI 脚本、player.gd、world.gd、除 project.godot 外的场景。
game_loaded 必须在 FarmManager.load_from_dict 之后 emit。
完成后：K 存 L 读，天/钱/背包/农田/作物阶段/玩家位置全部回滚，存档不存在按 L 不崩溃。
```
