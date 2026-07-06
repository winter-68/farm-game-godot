# T0：项目初始化与 Autoload 骨架

> 通用约束见 [../README.md](../README.md)。引擎 Godot 4.3+ / GDScript / Tab 缩进 / 占位素材 / 不加插件。

## 任务目标

搭好项目骨架：创建目录结构、`main.tscn` 根场景、注册 7 个 autoload（先建空壳，只有 `EventBus` 填入完整信号声明），保证项目能运行、控制台无报错。

## 需要创建的文件

- `scripts/autoload/event_bus.gd`（含 TECH_DESIGN 第 7 节的完整信号清单）
- `scripts/autoload/item_database.gd`、`time_manager.gd`、`inventory_manager.gd`、`farm_manager.gd`、`save_manager.gd`、`game_manager.gd`（均为 `extends Node` 的空壳，`_ready()` 里 `print("[X] ready")`）
- `scenes/main/main.tscn`（根节点 `Node`，名为 `Main`）
- 修改 `project.godot`：注册 autoload、设主场景为 `main.tscn`、配置输入映射（GDD 第 8 节动作名）、窗口与像素缩放设置。

## 不要修改的文件

- 无（首个任务）。但**不要**创建 T1+ 的数据类或其他脚本。

## 实现要求

1. Autoload 注册顺序严格按：`EventBus → ItemDatabase → TimeManager → InventoryManager → FarmManager → SaveManager → GameManager`。
2. `event_bus.gd` 填入全部 `signal` 声明，无其他逻辑。
3. 其余管理器仅 `extends Node` + `_ready()` 打印，不写业务逻辑。
4. Input Map 加入：`move_up/down/left/right`、`interact`、`use_tool`、`toggle_inventory`、`hotbar_1`~`hotbar_0`。
5. 渲染：`window/stretch/mode = "canvas_items"`，基础分辨率 `320×180`，允许整数缩放放大。

## 验收标准

- F5 运行，无报错；控制台出现每个管理器的 `ready` 打印。
- Project Settings 中 7 个 autoload 均在列且顺序正确。
- Input Map 含上述所有动作。

## Godot 测试步骤

1. 打开项目，按 F5。
2. 看「输出」面板是否有对应 `ready` 打印且无红色报错。
3. 打开 Project Settings → Autoload / Input Map 核对。

## 给 Codex 的执行提示词

```
你在一个空的 Godot 4.3 项目（GDScript）中工作，代号 Project Sprout。请完成项目骨架初始化。

创建目录与文件：
1) scripts/autoload/event_bus.gd —— extends Node，仅声明以下信号，无其它逻辑：
   request_use_item(item_id: StringName, cell: Vector2i)
   request_harvest(cell: Vector2i)
   time_changed(day: int, hour: int, minute: int)
   day_passed(new_day: int)
   money_changed(new_amount: int)
   inventory_changed()
   selected_slot_changed(index: int)
   tile_tilled(cell: Vector2i)
   tile_watered(cell: Vector2i)
   crop_planted(cell: Vector2i, crop_id: StringName)
   crop_grew(cell: Vector2i, stage: int)
   crop_harvested(cell: Vector2i, produce_id: StringName, amount: int)
   game_saved(slot: int)
   game_loaded(slot: int)
   request_open_shop()
2) 以下均为 extends Node 的空壳，_ready() 里 print("[名称] ready")：
   scripts/autoload/item_database.gd, time_manager.gd, inventory_manager.gd,
   farm_manager.gd, save_manager.gd, game_manager.gd
3) scenes/main/main.tscn：根节点 Node，命名 Main。

修改 project.godot：
- 注册 autoload，顺序：EventBus, ItemDatabase, TimeManager, InventoryManager,
  FarmManager, SaveManager, GameManager（名称=首字母大写，路径指向对应脚本）。
- 设置主场景为 res://scenes/main/main.tscn。
- 配置 Input Map 动作：move_up(W)、move_down(S)、move_left(A)、move_right(D)、
  interact(Space)、use_tool(J 和 鼠标左键)、toggle_inventory(Tab)、hotbar_1..hotbar_0(数字键1..0)。
- 显示设置：window/stretch/mode="canvas_items"，基础视口 320x180，允许整数放大。

约束：只创建上面列出的文件；不要创建任何数据类或玩家/世界脚本；不要引入插件或美术资源。
完成后运行应无报错，控制台打印 6 个管理器 ready。
```
