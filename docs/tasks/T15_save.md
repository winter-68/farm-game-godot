# T15：SaveManager 保存全部状态到 JSON

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现存档：把时间、背包+金币、农田、玩家位置汇总成 JSON，写入 `user://saves/slot_0.json`。玩家位置经 `GameManager`（world 注入 player 引用）获取。加一个调试键 `debug_save` 触发保存。**本任务只做"写"，读档在 T16。**

## 需要创建/修改的文件

- 修改 `scripts/autoload/save_manager.gd`：实现 `save_game(slot)`、`has_save(slot)`、路径与 JSON 写入。
- 修改 `scripts/autoload/farm_manager.gd`：新增 `to_save_dict()`（tiles → `{"x,y": tile.to_dict()}`）。
- 修改 `scripts/autoload/game_manager.gd`：`register_player()`、`get_player_position()`，并监听 `debug_save` 触发保存。
- 修改 `scripts/world/world.gd`：`_ready()` 里 `GameManager.register_player(player)`。
- 修改 `project.godot`：新增输入动作 `debug_save`（默认 `K`，键码 75）。

## 不要修改的文件

- `event_bus.gd`、`time_manager.gd`、`inventory_manager.gd`（已有 `to_save_dict`，只调用）、数据类、UI 脚本、场景 `.tscn`（除 `project.godot`）、`player.gd`。

## 实现要求

1. `FarmManager.to_save_dict() -> Dictionary`：
   - 返回 `{ "tiles": { "x,y": tile.to_dict(), ... } }`，键用 `"%d,%d" % [cell.x, cell.y]`。
2. `GameManager`：
   - `var _player: Node2D`；`func register_player(p): _player = p`
   - `func get_player_position() -> Vector2`：有 player 返回 `global_position`，否则 `Vector2.ZERO`
   - `_unhandled_input`：按下 `debug_save` → `SaveManager.save_game(0)`
3. `world.gd._ready()`：在既有注入之后加 `GameManager.register_player(player)`。
4. `SaveManager`：
   - `const SAVE_DIR := "user://saves"`；`func _slot_path(slot) -> String`
   - `func has_save(slot) -> bool`：`FileAccess.file_exists(_slot_path(slot))`
   - `func save_game(slot) -> void`：
     - 组装 `data = { "version": 1, "time": TimeManager.to_save_dict(), "inventory": InventoryManager.to_save_dict(), "farm": FarmManager.to_save_dict(), "player": { "pos_x": pos.x, "pos_y": pos.y } }`
     - 确保目录存在（`DirAccess.make_dir_recursive_absolute`）
     - `JSON.stringify(data, "\t")` 写入文件
     - emit `EventBus.game_saved(slot)`；`print("[SaveManager] saved slot %d" % slot)`
   - 金币已包含在 `InventoryManager.to_save_dict()` 里，无需单独存。

## 验收标准

- 运行中按 **K** → 输出面板打印 `[SaveManager] saved slot 0`，无报错。
- 通过 Godot 菜单 `Project → Open User Data Folder` → `saves/slot_0.json` 存在，内容含 time/inventory/farm/player 且数值合理（当前天数、金币、已翻耕格等）。
- 先翻地/种植/收获改变状态，再按 K，JSON 能反映最新状态。

## Godot 测试步骤

1. F5，做几步操作（翻地、种植、赚点钱）。
2. 按 K → 看输出打印。
3. `Project → Open User Data Folder` → 打开 `saves/slot_0.json` 核对内容。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现存档写入。

1) project.godot：新增输入动作 debug_save 绑定 K（physical_keycode 75）。不改其它动作。
2) scripts/autoload/farm_manager.gd 新增：
   func to_save_dict()->Dictionary:
     var out := {}
     for cell in tiles.keys():
       out["%d,%d" % [cell.x, cell.y]] = (tiles[cell] as FarmTile).to_dict()
     return {"tiles": out}
3) scripts/autoload/game_manager.gd：
   var _player: Node2D
   func register_player(p:Node2D)->void: _player=p
   func get_player_position()->Vector2: return _player.global_position if _player else Vector2.ZERO
   func _unhandled_input(_e): if Input.is_action_just_pressed("debug_save"): SaveManager.save_game(0)
4) scripts/world/world.gd._ready：末尾加 GameManager.register_player(player)
5) scripts/autoload/save_manager.gd：
   const SAVE_DIR := "user://saves"
   func _slot_path(slot:int)->String: return "%s/slot_%d.json" % [SAVE_DIR, slot]
   func has_save(slot:int)->bool: return FileAccess.file_exists(_slot_path(slot))
   func save_game(slot:int)->void:
     var pos := GameManager.get_player_position()
     var data := {
       "version":1,
       "time":TimeManager.to_save_dict(),
       "inventory":InventoryManager.to_save_dict(),
       "farm":FarmManager.to_save_dict(),
       "player":{"pos_x":pos.x,"pos_y":pos.y},
     }
     DirAccess.make_dir_recursive_absolute(SAVE_DIR)
     var f := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
     if f == null: push_warning("[SaveManager] cannot open save file"); return
     f.store_string(JSON.stringify(data, "\t")); f.close()
     EventBus.game_saved.emit(slot)
     print("[SaveManager] saved slot %d" % slot)

约束：不要修改 event_bus.gd、time_manager.gd、inventory_manager.gd(只调用其 to_save_dict)、
数据类、UI 脚本、除 project.godot 外的场景、player.gd。
完成后：按 K 保存，user://saves/slot_0.json 生成且内容正确，无报错。
```
