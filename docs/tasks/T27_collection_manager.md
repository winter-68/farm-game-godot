# T27：收集系统 — CollectionManager（数据层）

> 通用约束见 [../README.md](../README.md)。批次 F（收集系统）第 1 个任务。

## 任务目标

新增收集系统的数据地基：追踪**图鉴发现**（收获过哪些作物产出）与**统计数据**，据此解锁**成就**，通过 EventBus 广播、纳入存档。**本卡不做 UI**（面板在 T28、提示在 T29），用控制台 print 验证解锁。

## 架构要点（务必遵守）

1. **CollectionManager 是新 Autoload，注册在 `WeatherManager` 之后、`SaveManager` 之前**。它只读 `ItemDatabase`/`TimeManager`、只监听 EventBus 信号，不搜场景树、不改别的管理器状态。
2. **读档守卫（关键）**：`crop_harvested`/`money_changed`/`season_changed` 等信号在**读档时也会被各管理器 emit**。若 CollectionManager 直接响应，会在读档过程中误判解锁、发出错误提示。因此新增 `save_load_started` 信号：读档开始时置 `_loading=true`，`game_loaded` 时置回 false；`_loading` 期间所有信号响应直接 return，权威状态由 `load_from_dict` 直接写入。
3. 数据/表现分离：本卡只发信号 + print；面板/提示是后续卡的表现层。

## 需要创建/修改的文件

- **新建** `scripts/autoload/collection_manager.gd`
- 修改 `project.godot`：在 `WeatherManager` 之后、`SaveManager` 之前注册 `CollectionManager`
- 修改 `scripts/autoload/event_bus.gd`：加 3 个信号
- 修改 `scripts/autoload/game_manager.gd`：`new_game()` 调 `CollectionManager.new_game()`
- 修改 `scripts/autoload/save_manager.gd`：`load_game()` 开头 emit `save_load_started`；存/读加 `"collection"` 段

## 不要修改的文件

- `item_database.gd`、`time_manager.gd`、`weather_manager.gd`、`farm_manager.gd`、`inventory_manager.gd`、数据类、所有 UI、所有场景、`player.gd`。

## 实现要求

### 1) `event_bus.gd` 新增信号

```gdscript
signal collection_discovered(produce_id: StringName)
signal achievement_unlocked(achievement_id: StringName, title: String)
signal save_load_started()
```

### 2) `scripts/autoload/collection_manager.gd`（新建）

```gdscript
extends Node

# 成就定义，顺序即面板展示顺序。
const ACHIEVEMENTS := [
	{"id": &"first_harvest", "title": "初次收获", "desc": "收获第一份作物"},
	{"id": &"harvest_50", "title": "小有收成", "desc": "累计收获 50 份作物"},
	{"id": &"harvest_200", "title": "丰收能手", "desc": "累计收获 200 份作物"},
	{"id": &"collector", "title": "作物学家", "desc": "图鉴集齐所有作物"},
	{"id": &"all_seasons", "title": "四季轮回", "desc": "经历春夏秋冬四个季节"},
	{"id": &"rich", "title": "小富农", "desc": "金币达到 1000"},
	{"id": &"first_season", "title": "扎根", "desc": "坚持到第 28 天"},
]

var discovered: Dictionary = {}      # String(produce_id) -> true
var total_harvested: int = 0
var max_money: int = 0
var seasons_seen: Dictionary = {}    # int(season) -> true
var unlocked: Dictionary = {}        # String(id) -> true

var _loading: bool = false


func _ready() -> void:
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.save_load_started.connect(_on_save_load_started)
	EventBus.game_loaded.connect(_on_game_loaded)


## Resets all collection/achievement progress for a new game.
func new_game() -> void:
	discovered.clear()
	total_harvested = 0
	max_money = 0
	seasons_seen.clear()
	unlocked.clear()
	seasons_seen[TimeManager.season] = true


func is_discovered(produce_id: StringName) -> bool:
	return discovered.has(String(produce_id))


func is_unlocked(achievement_id: StringName) -> bool:
	return unlocked.has(String(achievement_id))


## Total number of PRODUCE items = the full 图鉴 size.
func total_produce_count() -> int:
	var n := 0
	for item: ItemData in ItemDatabase.get_all_items():
		if item != null and item.type == ItemData.Type.PRODUCE:
			n += 1
	return n


func discovered_count() -> int:
	return discovered.size()


func to_save_dict() -> Dictionary:
	return {
		"discovered": discovered.keys(),
		"total_harvested": total_harvested,
		"max_money": max_money,
		"seasons_seen": seasons_seen.keys(),
		"unlocked": unlocked.keys(),
	}


## Restores progress WITHOUT replaying unlock notifications.
func load_from_dict(d: Dictionary) -> void:
	discovered.clear()
	for k in d.get("discovered", []):
		discovered[String(k)] = true
	total_harvested = int(d.get("total_harvested", 0))
	max_money = int(d.get("max_money", 0))
	seasons_seen.clear()
	for s in d.get("seasons_seen", []):
		seasons_seen[int(s)] = true
	unlocked.clear()
	for u in d.get("unlocked", []):
		unlocked[String(u)] = true


func _on_save_load_started() -> void:
	_loading = true


func _on_game_loaded(_slot: int) -> void:
	_loading = false


func _on_crop_harvested(_cell: Vector2i, produce_id: StringName, amount: int) -> void:
	if _loading:
		return
	total_harvested += maxi(amount, 0)
	if not discovered.has(String(produce_id)):
		discovered[String(produce_id)] = true
		EventBus.collection_discovered.emit(produce_id)
	_evaluate()


func _on_money_changed(new_amount: int) -> void:
	if _loading:
		return
	if new_amount > max_money:
		max_money = new_amount
	_evaluate()


func _on_season_changed(_season_name: String) -> void:
	if _loading:
		return
	seasons_seen[TimeManager.season] = true
	_evaluate()


func _on_day_passed(_new_day: int) -> void:
	if _loading:
		return
	_evaluate()


func _evaluate() -> void:
	if total_harvested >= 1:
		_unlock(&"first_harvest")
	if total_harvested >= 50:
		_unlock(&"harvest_50")
	if total_harvested >= 200:
		_unlock(&"harvest_200")
	var produce_total := total_produce_count()
	if produce_total > 0 and discovered_count() >= produce_total:
		_unlock(&"collector")
	if seasons_seen.size() >= 4:
		_unlock(&"all_seasons")
	if max_money >= 1000:
		_unlock(&"rich")
	if TimeManager.day >= 28:
		_unlock(&"first_season")


func _unlock(id: StringName) -> void:
	if unlocked.has(String(id)):
		return
	unlocked[String(id)] = true
	var title := _title_of(id)
	print("[Collection] 解锁成就：%s" % title)  # T29 接入 toast 后可保留或移除
	EventBus.achievement_unlocked.emit(id, title)


func _title_of(id: StringName) -> String:
	for a in ACHIEVEMENTS:
		if a["id"] == id:
			return String(a["title"])
	return String(id)
```

### 3) `project.godot` autoload

在 `WeatherManager` 行之后、`SaveManager` 之前插入：
```
CollectionManager="*res://scripts/autoload/collection_manager.gd"
```

### 4) `game_manager.gd`

`new_game()` 中，`WeatherManager.new_game()` 之后加：
```gdscript
	CollectionManager.new_game()
```

### 5) `save_manager.gd`

- `save_game()` 的 `data` 字典加：`"collection": CollectionManager.to_save_dict(),`
- `load_game()` 中，**解析出合法 data 之后、调用各 `load_from_dict` 之前**，加一行：
  `EventBus.save_load_started.emit()`
- 在 `WeatherManager.load_from_dict(...)` 之后加：
  `CollectionManager.load_from_dict(data.get("collection", {}))`
- 末尾原有的 `EventBus.game_loaded.emit(slot)` 保持不动（它负责把 `_loading` 复位）。

## 验收标准

- 新游戏收获第一份作物 → 控制台打印「[Collection] 解锁成就：初次收获」，且再收获同种作物**不再重复**打印。
- 收满 50 份 → 打印「小有收成」。
- 集齐 4 种作物 → 打印「作物学家」。
- 睡到第 28 天 → 打印「扎根」。
- 金币达到 1000 → 打印「小富农」。
- **存档 → 读档**：不会重复打印任何已解锁成就（读档守卫生效）；读档后 `CollectionManager.unlocked/discovered/total_harvested` 与存档一致。
- 无报错。

## Godot 测试步骤

1. F5 新游戏 → 种收一份 → 看控制台「初次收获」。
2. 反复种收，观察 50 份「小有收成」、集齐四种「作物学家」。
3. `debug_save` → `debug_load` → 确认**没有**重复解锁刷屏。
4.（可选）临时把某成就阈值调小快速验证四季/金币成就。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）新增收集系统数据层 CollectionManager，本步不做 UI，用 print 验证。

1) event_bus.gd 加 3 信号：collection_discovered(produce_id: StringName)、
   achievement_unlocked(achievement_id: StringName, title: String)、save_load_started()
2) 新建 scripts/autoload/collection_manager.gd —— 完整内容见 T27 任务卡实现要求第 2 节，原样照抄。
3) project.godot：在 WeatherManager 之后、SaveManager 之前注册
   CollectionManager="*res://scripts/autoload/collection_manager.gd"
4) game_manager.gd new_game()：WeatherManager.new_game() 后加 CollectionManager.new_game()
5) save_manager.gd：save 的 data 加 "collection": CollectionManager.to_save_dict()；
   load_game() 解析出合法 data 后、调用各 load_from_dict 之前 emit EventBus.save_load_started()；
   WeatherManager.load_from_dict 之后加 CollectionManager.load_from_dict(data.get("collection", {}))；
   末尾 game_loaded.emit 不动。

关键：读档守卫。crop_harvested/money_changed/season_changed 在读档时也会被 emit，
CollectionManager 的这些回调开头都要 if _loading: return；_loading 由 save_load_started 置真、
game_loaded 置假。否则读档会误弹成就。

约束：不要改 item_database.gd、time_manager.gd、weather_manager.gd、farm_manager.gd、
inventory_manager.gd、数据类、任何 UI/场景、player.gd。
完成后：收获/游玩会按阈值解锁成就并 print（不重复）；存读档不重复刷屏、状态一致；无报错。
```
