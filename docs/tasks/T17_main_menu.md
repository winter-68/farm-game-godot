# T17：主菜单（新游戏 / 继续 / 退出）

> 通用约束见 [../README.md](../README.md)。这是 MVP 收尾任务，涉及启动流程重构，改动面较大但每处都是最小增量。

## 任务目标

加入主菜单作为**启动场景**：`新游戏`（重置状态进游戏）、`继续`（读档进游戏，仅有存档时可用）、`退出`。`main.tscn` 保持为**游戏场景**；新建 `main_menu.tscn` 为项目主场景。用 `GameManager` 协调"重置/待读档"握手。

## 需要创建/修改的文件

- 创建 `scenes/ui/main_menu.tscn` + `scripts/ui/main_menu.gd`。
- 修改 `scripts/autoload/game_manager.gd`：`new_game()`、`continue_game()`、`consume_pending_load()`。
- 修改 `scripts/autoload/time_manager.gd`：`new_game()`（重置到第1天06:00）。
- 修改 `scripts/autoload/inventory_manager.gd`：`new_game()`（公开包装 `_setup_new_game`）。
- 修改 `scripts/autoload/farm_manager.gd`：`new_game()`（清空 tiles + 清 FarmLayer）。
- 修改 `scripts/world/world.gd`：`_ready` 末尾按需触发**延迟读档**。
- 修改 `scripts/ui/hud.gd`：金币初始化改为读 `InventoryManager.money`（修复经菜单进场时的时序）。
- 修改 `project.godot`：主场景改为 `main_menu.tscn`。

## 不要修改的文件

- `event_bus.gd`、数据类、`player.gd`、`crop_view.gd`、`hotbar.gd`、`inventory_ui.gd`、`shop_ui.gd`、`main.tscn`、`world.tscn` 等场景（除 `project.godot`）。

## 实现要求

1. **`GameManager`**：
   - `var _pending_load: bool = false`
   - `func new_game() -> void`：`_pending_load = false`；`TimeManager.new_game()`；`InventoryManager.new_game()`；`FarmManager.new_game()`；`get_tree().change_scene_to_file("res://scenes/main/main.tscn")`
   - `func continue_game() -> void`：`_pending_load = true`；`change_scene_to_file("res://scenes/main/main.tscn")`
   - `func consume_pending_load() -> bool`：返回 `_pending_load` 并置回 false
2. **各管理器 `new_game()`**：
   - `TimeManager`：`day=1; hour=6; minute=0; _elapsed_seconds=0`；emit `time_changed`
   - `InventoryManager`：直接调用已有 `_setup_new_game()`
   - `FarmManager`：遍历 `tiles.keys()` `if _farm: _farm.erase_cell(cell)`；`tiles.clear()`
3. **`world.gd._ready()`**（在既有注入之后）：
   ```
   if GameManager.consume_pending_load():
       call_deferred("_deferred_load")
   ```
   新增 `func _deferred_load() -> void: SaveManager.load_game(0)`
   > 用 `call_deferred` 确保 HUD/Hotbar/CropView 都 `_ready` 完毕、信号已连上，读档 emit 才不会被漏收。
4. **`hud.gd._ready()`**：把 `_on_money_changed(_money)` 改为 `_on_money_changed(InventoryManager.money)`（其余不动）。
5. **`main_menu.gd`**：
   - `_ready`：`继续`按钮 `disabled = not SaveManager.has_save(0)`；三个按钮 `pressed` 分别接 `GameManager.new_game()` / `GameManager.continue_game()` / `get_tree().quit()`。
6. **`main_menu.tscn`**：`Control` 根 + 标题 + 三个 `Button`（新游戏 / 继续 / 退出）。
7. `project.godot`：`run/main_scene = "res://scenes/ui/main_menu.tscn"`。

## 验收标准

- 启动 → 先见主菜单。首次运行（无存档）`继续`置灰。
- `新游戏` → 进游戏，金币 500、第1天、空农田、快捷栏正常。
- 玩几步 → 按 K 存档 → 退出程序重开 → 主菜单 `继续` 可点 → `继续` → 状态回到存档时刻（天/钱/农田/作物/位置）。
- `退出` 关闭游戏。
- 全程无报错。

## Godot 测试步骤

1. F5 → 主菜单，确认无存档时"继续"置灰。
2. 新游戏 → 确认初始状态；操作若干 → K 存档。
3. 停止运行、再 F5 → "继续"可用 → 点它 → 核对状态回滚。
4. 点"退出"确认关闭。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）加入主菜单并重构启动流程。main.tscn 保持为游戏场景。

1) project.godot：run/main_scene 改为 "res://scenes/ui/main_menu.tscn"。
2) scenes/ui/main_menu.tscn：Control 根 + 标题 Label + 三个 Button(新游戏/继续/退出，建议 VBox)。
3) scripts/ui/main_menu.gd（挂 Control 根）：
   _ready:
     $继续Button.disabled = not SaveManager.has_save(0)
     新游戏.pressed.connect(GameManager.new_game)
     继续.pressed.connect(GameManager.continue_game)
     退出.pressed.connect(get_tree().quit)
4) scripts/autoload/game_manager.gd：
   var _pending_load := false
   func new_game(): _pending_load=false; TimeManager.new_game(); InventoryManager.new_game()
     FarmManager.new_game(); get_tree().change_scene_to_file("res://scenes/main/main.tscn")
   func continue_game(): _pending_load=true
     get_tree().change_scene_to_file("res://scenes/main/main.tscn")
   func consume_pending_load()->bool: var v=_pending_load; _pending_load=false; return v
5) scripts/autoload/time_manager.gd：
   func new_game(): day=1;hour=6;minute=0;_elapsed_seconds=0; EventBus.time_changed.emit(day,hour,minute)
6) scripts/autoload/inventory_manager.gd：func new_game(): _setup_new_game()
7) scripts/autoload/farm_manager.gd：
   func new_game():
     for cell in tiles.keys():
       if _farm: _farm.erase_cell(cell)
     tiles.clear()
8) scripts/world/world.gd._ready 末尾：
   if GameManager.consume_pending_load(): call_deferred("_deferred_load")
   新增 func _deferred_load(): SaveManager.load_game(0)
9) scripts/ui/hud.gd._ready：把 _on_money_changed(_money) 改为 _on_money_changed(InventoryManager.money)

约束：不要修改 event_bus.gd、数据类、player.gd、crop_view.gd、hotbar.gd、inventory_ui.gd、
shop_ui.gd、以及除 project.godot 外的既有场景。
完成后：启动见菜单；新游戏进初始局；K 存档后重开可"继续"回滚；退出可用；无报错。
```
