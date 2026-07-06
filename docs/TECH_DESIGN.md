# 技术架构文档（TECH_DESIGN）— Project Sprout

引擎 **Godot 4.3+**，语言 **GDScript**。若实际为 4.2，将文中 `TileMapLayer` 替换为 `TileMap` 的多 layer 形式（相关任务卡已注明）。

---

## 1. 架构原则

1. **数据与表现分离**：农田/背包/时间的**状态**是纯数据（Dictionary / Resource），场景节点只负责**显示与输入**。
2. **信号总线解耦（EventBus）**：系统之间不直接互相持有引用，通过 `EventBus` autoload 发/收信号。让每个任务改动面小、互不打架。
3. **单一数据源（Single Source of Truth）**：每类状态只有一个「拥有者」（如金币只在 `InventoryManager`），其他人只读 + 监听信号。
4. **存档 = 序列化各管理器状态**：每个管理器实现 `to_save_dict()` / `load_from_dict()`，`SaveManager` 只做汇总与文件读写。
5. **Autoload 不主动搜索场景树**：需要场景节点（如 TileMapLayer）时，由场景在 `_ready()` 通过 `register_*()` 注入引用。

---

## 2. 分层

```
┌─────────────────────────────────────────────┐
│  表现层 Scenes/UI  (Player, FarmLand, HUD…)   │  ← 只读状态、发输入信号
├─────────────────────────────────────────────┤
│  信号总线 EventBus (autoload)                 │  ← 全局解耦通道
├─────────────────────────────────────────────┤
│  系统层 Managers (autoload)                    │
│  Game / Time / Inventory / Farm / Save / DB   │  ← 拥有并修改状态
├─────────────────────────────────────────────┤
│  数据层 Resources (.tres) + 纯数据类            │  ← ItemData / CropData / 存档字典
└─────────────────────────────────────────────┘
```

---

## 3. 关键技术选型

| 主题 | 选型 | 理由 |
|------|------|------|
| 瓦片地图 | `TileMapLayer`（4.3+）分层：地面层 + 农田层 | 农田状态叠加显示，逻辑与地面解耦 |
| 农田状态存储 | `FarmManager` 中 `Dictionary[Vector2i → FarmTile]` | 存档友好，与显示分离 |
| 作物显示 | `Crop` 场景实例，挂在 `CropsRoot` 下，按 `Vector2i` 定位 | 易实现，阶段切换=换贴图 |
| 目标瓦片 | 玩家坐标转 cell + 面朝方向偏移 | 交互指向明确 |
| 物品/作物定义 | 自定义 `Resource`（`.tres`） | 策划可视化编辑，热扩展 |
| 存档格式 | JSON（`user://saves/slot_N.json`） | 透明、易调试 |
| 全局通信 | `EventBus` 信号 autoload | 解耦、可测试 |
| 渲染缩放 | 视口 `canvas_items` 拉伸 + 整数缩放 | 像素清晰 |

---

## 4. 「使用工具」的统一分发逻辑（核心设计）

玩家不判断「现在该翻地还是浇水」，而是**根据当前选中的物品/工具类型**决定行为，交给 `FarmManager` 处理：

```
Player 按 use_tool
  → 取当前选中项 selected_item (工具或种子)
  → 计算 target_cell
  → EventBus.request_use_item.emit(selected_item, target_cell)
FarmManager 监听 request_use_item：
  锄头 → 尝试翻地        浇水壶 → 尝试浇水
  种子 → 尝试播种(需已翻地)   —— 校验通过才改状态并回发结果信号
```

好处：新增工具（镰刀、铲子等）只在 `FarmManager` 加一个分支，不动 Player。

---

## 5. Godot 项目目录结构

```
res://
├── project.godot
├── docs/                          # 规划文档（本目录）
├── assets/
│   ├── sprites/{player,crops,tiles}/
│   └── fonts/
├── scenes/
│   ├── main/main.tscn             # 游戏根场景
│   ├── world/
│   │   ├── world.tscn             # 农场关卡
│   │   ├── player/player.tscn
│   │   └── farm/crop.tscn         # 单株作物
│   └── ui/
│       ├── hud.tscn
│       ├── inventory_ui.tscn
│       ├── hotbar.tscn
│       └── shop_ui.tscn
├── scripts/
│   ├── autoload/
│   │   ├── event_bus.gd
│   │   ├── game_manager.gd
│   │   ├── time_manager.gd
│   │   ├── inventory_manager.gd
│   │   ├── farm_manager.gd
│   │   ├── item_database.gd
│   │   └── save_manager.gd
│   ├── data/
│   │   ├── item_data.gd           # class_name ItemData (Resource)
│   │   ├── crop_data.gd           # class_name CropData (Resource)
│   │   └── farm_tile.gd           # class_name FarmTile (纯数据)
│   ├── world/
│   │   ├── world.gd
│   │   ├── player.gd
│   │   └── crop.gd
│   └── ui/
│       ├── hud.gd
│       ├── inventory_ui.gd
│       ├── hotbar.gd
│       └── shop_ui.gd
├── resources/
│   ├── items/                     # ItemData 的 .tres
│   ├── crops/                     # CropData 的 .tres
│   └── tiles/                     # TileSet 占位
└── addons/                        # 预留（暂空）
```

**约定**：脚本放 `scripts/`、场景放 `scenes/`，两者按功能子目录对应；资源 `.tres` 放 `resources/`；存档运行时写到 `user://saves/`（不进版本库）。

---

## 6. 场景（Scene）拆分方案

| 场景 | 根节点类型 | 职责 | 关键子节点 |
|------|-----------|------|-----------|
| `main.tscn` | `Node` | 游戏入口，装载世界 + UI 层 | `World`(instance)、`CanvasLayer/UI`(HUD/Inventory/Shop) |
| `world.tscn` | `Node2D` | 农场关卡 | `GroundLayer`(TileMapLayer)、`FarmLayer`(TileMapLayer)、`CropsRoot`(Node2D)、`Player`(instance)、`TileHighlight` |
| `player.tscn` | `CharacterBody2D` | 移动、朝向、发起「使用工具」 | `Sprite2D`(占位)、朝向指示、`Camera2D` |
| `crop.tscn` | `Node2D` | 单株作物显示 | `Sprite2D`（按阶段换贴图）|
| `hud.tscn` | `Control` | 显示时间/天数/金币/选中项 | `Label` 若干 |
| `inventory_ui.tscn` | `Control` | 背包格子显示，开关 | `GridContainer` |
| `hotbar.tscn` | `Control` | 快捷栏，高亮选中格 | `HBoxContainer` |
| `shop_ui.tscn` | `Control` | 出售/购买界面 | 列表 + 按钮 |

**装配关系**：`main` 是唯一常驻场景；`world` 是它的子场景；UI 全在 `main` 的 `CanvasLayer` 里，避免被相机缩放影响。管理器都是 autoload，不进场景树层级。

**层级/渲染顺序**（world 内）：`GroundLayer` < `FarmLayer` < `CropsRoot` < `Player`。

---

## 7. Autoload 单例设计

在 `Project Settings → Autoload` 按此顺序注册（被依赖者在前）：

| 顺序 | 名称 | 脚本 | 职责 | 主要 API（签名，非实现） |
|---|------|------|------|------|
| 1 | `EventBus` | `event_bus.gd` | 全局信号中枢，**无逻辑**只声明 signal | 见下方信号清单 |
| 2 | `ItemDatabase` | `item_database.gd` | 启动时加载所有 `ItemData`/`CropData` | `get_item(id)`, `get_crop(id)`, `get_all_items()` |
| 3 | `TimeManager` | `time_manager.gd` | 时钟推进、天数、睡觉 | `advance_to_next_day()`, `to_save_dict()`, `load_from_dict()` |
| 4 | `InventoryManager` | `inventory_manager.gd` | 背包槽 + 金币 + 选中项 | `add_item()`,`remove_item()`,`add_money()`,`try_spend()`,`get_selected()`,`set_selected(i)` |
| 5 | `FarmManager` | `farm_manager.gd` | 农田瓦片状态、翻地/浇水/播种/成长/收获 | `till()`,`water()`,`plant()`,`harvest()`,`_on_day_passed()` |
| 6 | `SaveManager` | `save_manager.gd` | 汇总各管理器状态读写 JSON | `save_game(slot)`, `load_game(slot)`, `has_save(slot)` |
| 7 | `GameManager` | `game_manager.gd` | 全局流程/新游戏/开始/暂停（较薄） | `new_game()`, `is_paused` |

### EventBus 信号清单（MVP 全集，先声明好，后续任务往里填）

```gdscript
# —— 输入意图（Player/UI → 系统） ——
signal request_use_item(item_id: StringName, cell: Vector2i)  # 使用锄头/浇水壶/种子
signal request_harvest(cell: Vector2i)

# —— 时间 ——
signal time_changed(day: int, hour: int, minute: int)
signal day_passed(new_day: int)

# —— 金币 / 背包 ——
signal money_changed(new_amount: int)
signal inventory_changed()
signal selected_slot_changed(index: int)

# —— 农田 / 作物 ——
signal tile_tilled(cell: Vector2i)
signal tile_watered(cell: Vector2i)
signal crop_planted(cell: Vector2i, crop_id: StringName)
signal crop_grew(cell: Vector2i, stage: int)
signal crop_harvested(cell: Vector2i, produce_id: StringName, amount: int)

# —— 存档 / 流程 ——
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal request_open_shop()
```

**规则**：信号只在「拥有该状态的管理器」里 emit（如 `money_changed` 只由 `InventoryManager` 发）。输入类 `request_*` 由 UI/Player 发、由管理器收。

---

## 8. 数据结构设计

### 8.1 `ItemData`（Resource, `item_data.gd`）

```gdscript
class_name ItemData extends Resource
enum Type { SEED, PRODUCE, TOOL, MISC }

@export var item_id: StringName          # 唯一 id，如 &"seed_greenbean"
@export var display_name: String
@export var type: Type
@export var icon: Texture2D              # 占位可空
@export var buy_price: int = 0           # 商店买入价（0=不可买）
@export var sell_price: int = 0          # 出售价（0=不可卖）
@export var stackable: bool = true
@export var max_stack: int = 99
@export var linked_crop_id: StringName   # 仅 SEED：种下后对应的 CropData id
```

### 8.2 `CropData`（Resource, `crop_data.gd`）

```gdscript
class_name CropData extends Resource
@export var crop_id: StringName          # 如 &"crop_greenbean"
@export var display_name: String
@export var produce_item_id: StringName  # 收获产出的 ItemData id
@export var days_per_stage: int = 1      # 每阶段需要的「已浇水天数」
@export var stage_textures: Array[Texture2D]  # 长度=阶段数；最后一张=成熟
@export var regrows: bool = false        # 收获后是否回到某阶段继续结果
@export var regrow_to_stage: int = 0
@export var produce_amount: int = 1

func mature_stage() -> int:              # 成熟阶段索引
	return stage_textures.size() - 1
```

### 8.3 `FarmTile`（纯数据类, `farm_tile.gd`）

```gdscript
class_name FarmTile extends RefCounted
var tilled: bool = false
var watered: bool = false          # 当天是否已浇水（跨天清空）
var crop_id: StringName = &""      # 空=无作物
var stage: int = 0                 # 当前成长阶段
var watered_days: int = 0          # 累计有效浇水天数（驱动 stage）
var harvestable: bool = false

func to_dict() -> Dictionary: ...
static func from_dict(d: Dictionary) -> FarmTile: ...
```

### 8.4 背包槽（`InventoryManager` 内部）

```gdscript
# var slots: Array = []            # 固定长度（如 24）
# 每槽: { "item_id": StringName, "quantity": int }
# 空槽:  { "item_id": &"", "quantity": 0 }
# var selected_index: int = 0
```

### 8.5 存档 JSON 结构（`user://saves/slot_0.json`）

```json
{
  "version": 1,
  "time":   { "day": 3, "hour": 8, "minute": 30 },
  "money":  120,
  "inventory": {
    "selected_index": 0,
    "slots": [ {"item_id":"seed_greenbean","quantity":5}, {"item_id":"","quantity":0} ]
  },
  "farm": {
    "tiles": {
      "3,2": {"tilled":true,"watered":false,"crop_id":"crop_greenbean","stage":1,"watered_days":1,"harvestable":false}
    }
  },
  "player": { "pos_x": 128.0, "pos_y": 96.0 }
}
```

**约定**：`Vector2i` 键序列化为 `"x,y"` 字符串；`version` 字段用于未来存档迁移。

---

## 9. 存档流程

```
保存: SaveManager.save_game(slot)
  → 收集 { time, inventory, farm, player } 各自的 to_save_dict()
  → 写 JSON 到 user://saves/slot_N.json → EventBus.game_saved.emit(slot)

读取: SaveManager.load_game(slot)
  → 读 JSON → 分发给各 Manager.load_from_dict()
  → EventBus.game_loaded.emit(slot) → UI/World 重建显示
```
