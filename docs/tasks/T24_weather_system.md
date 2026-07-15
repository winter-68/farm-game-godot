# T24：天气系统 — WeatherManager + HUD 显示

> 通用约束见 [../README.md](../README.md)。批次 E（天气系统）第 1 个任务。

## 任务目标

新增天气系统的数据地基：每天随机出一种天气（按季节概率），通过 EventBus 广播，HUD 显示当前天气，并纳入存档。**本卡不做任何玩法效果**（自动浇水在 T25，视觉在 T26），只做「天气存在、会变、显示、存读档」。

## 架构要点（务必遵守）

- **WeatherManager 是新 Autoload，必须注册在 `FarmManager` 之后**（`project.godot` 的 autoload 顺序）。原因：T25 的雨天自动浇水依赖「FarmManager 先处理成长并清掉浇水标记 → WeatherManager 再补雨水」的信号回调顺序；Godot 按信号连接顺序回调，autoload 按注册顺序 `_ready`，所以 Weather 必须排在 Farm 后面。本卡就把顺序定死，后续卡不再改。
- 天气是**数据**，HUD 是**表现**，靠 `weather_changed` 信号解耦。WeatherManager 不搜场景树。

## 需要创建/修改的文件

- **新建** `scripts/autoload/weather_manager.gd`
- 修改 `project.godot`：在 `FarmManager` 行**之后**注册 `WeatherManager`
- 修改 `scripts/autoload/event_bus.gd`：加 `weather_changed` 信号
- 修改 `scripts/autoload/game_manager.gd`：`new_game()` 调 `WeatherManager.new_game()`
- 修改 `scripts/autoload/save_manager.gd`：存/读加 `"weather"` 段
- 修改 `scripts/ui/hud.gd`：显示天气
- 修改 `scenes/ui/hud.tscn`：在时间/金币的 VBox 里加一个 `WeatherLabel`

## 不要修改的文件

- `farm_manager.gd`、`time_manager.gd`、`inventory_manager.gd`、数据类、其他 UI、`player.gd`、除 `hud.tscn` 外的场景。

## 实现要求

### 1) `scripts/autoload/weather_manager.gd`（新建）

```gdscript
extends Node

enum Weather { SUNNY, CLOUDY, RAIN, SNOW }

const WEATHER_NAMES := {
	Weather.SUNNY: "晴",
	Weather.CLOUDY: "多云",
	Weather.RAIN: "雨",
	Weather.SNOW: "雪",
}

# 季节索引 0春 1夏 2秋 3冬 → [[天气, 权重], ...]，权重无需求和为 1。
const SEASON_TABLE := {
	0: [[Weather.SUNNY, 50], [Weather.CLOUDY, 20], [Weather.RAIN, 30]],
	1: [[Weather.SUNNY, 45], [Weather.CLOUDY, 15], [Weather.RAIN, 40]],
	2: [[Weather.SUNNY, 55], [Weather.CLOUDY, 20], [Weather.RAIN, 25]],
	3: [[Weather.SUNNY, 50], [Weather.CLOUDY, 20], [Weather.SNOW, 30]],
}

var current_weather: int = Weather.SUNNY


func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)


## Rolls the opening-day weather for a fresh game.
func new_game() -> void:
	current_weather = _roll_weather(TimeManager.season)
	EventBus.weather_changed.emit(current_weather, get_weather_name())


## Whether today's weather auto-waters crops (rain only for now).
func waters_crops() -> bool:
	return current_weather == Weather.RAIN


## Current weather display name.
func get_weather_name() -> String:
	return WEATHER_NAMES.get(current_weather, "晴")


## Save-friendly weather state.
func to_save_dict() -> Dictionary:
	return {"current": current_weather}


## Restores weather state and notifies listeners once.
func load_from_dict(d: Dictionary) -> void:
	current_weather = clampi(int(d.get("current", Weather.SUNNY)), 0, Weather.SNOW)
	EventBus.weather_changed.emit(current_weather, get_weather_name())


func _on_day_passed(_new_day: int) -> void:
	current_weather = _roll_weather(TimeManager.season)
	EventBus.weather_changed.emit(current_weather, get_weather_name())
	# T25 将在此后追加：if waters_crops(): FarmManager.water_all_tilled()


func _roll_weather(season: int) -> int:
	var table: Array = SEASON_TABLE.get(season, SEASON_TABLE[0])
	var total := 0
	for entry in table:
		total += int(entry[1])
	var pick := randi() % maxi(total, 1)
	var acc := 0
	for entry in table:
		acc += int(entry[1])
		if pick < acc:
			return int(entry[0])
	return Weather.SUNNY
```

### 2) `project.godot` autoload 顺序

在 `FarmManager="*res://scripts/autoload/farm_manager.gd"` **之后**、`SaveManager` 之前插入：
```
WeatherManager="*res://scripts/autoload/weather_manager.gd"
```

### 3) `event_bus.gd`

在时间相关信号附近加：
```gdscript
signal weather_changed(weather_id: int, weather_name: String)
```

### 4) `game_manager.gd`

`new_game()` 中，`FarmManager.new_game()` 之后加一行：
```gdscript
	WeatherManager.new_game()
```

### 5) `save_manager.gd`

- `save_game()` 的 `data` 字典里加：`"weather": WeatherManager.to_save_dict(),`
- `load_game()` 里，`FarmManager.load_from_dict(...)` 之后加：
  `WeatherManager.load_from_dict(data.get("weather", {}))`

### 6) `hud.tscn` + `hud.gd`

- `hud.tscn`：在 `MarginContainer/VBoxContainer` 里，`MoneyLabel` 之后照 `MoneyLabel` 的格式加一个 `WeatherLabel: Label`。
- `hud.gd`：
  - 加 `@onready var weather_label: Label = $MarginContainer/VBoxContainer/WeatherLabel`
  - `_ready()` 里 `EventBus.weather_changed.connect(_on_weather_changed)`，并主动拉一次当前值：
    `_on_weather_changed(WeatherManager.current_weather, WeatherManager.get_weather_name())`
  - 新方法：
    ```gdscript
    func _on_weather_changed(_id: int, weather_name: String) -> void:
    	weather_label.text = "天气: %s" % weather_name
    ```

## 验收标准

- F5 新游戏 → HUD 出现「天气: 晴/多云/雨」（春季不会出现「雪」）。
- 反复按睡觉键（`debug_sleep`）跨天 → 天气会变化，且符合季节（冬天出现「雪」，不出现「雨」）。
- 存档（`debug_save`）→ 改几天 → 读档（`debug_load`）→ HUD 天气回到存档时的天气。
- 无报错、无警告。

## Godot 测试步骤

1. F5 新游戏 → 看 HUD 天气字段。
2. 连按睡觉键多次 → 天气应随机变化。
3. 一直睡到冬季（或临时把起始 `season` 调 3 测试）→ 确认冬天是「雪」不是「雨」。
4. 存档 → 跨几天 → 读档 → 天气恢复。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）新增天气系统数据层，本步不做玩法效果，只做天气随机+显示+存档。

1) 新建 scripts/autoload/weather_manager.gd —— 完整内容见 T24 任务卡「实现要求」第 1 节，原样照抄。
2) project.godot：在 FarmManager 行之后、SaveManager 之前注册
   WeatherManager="*res://scripts/autoload/weather_manager.gd"
   （顺序很关键，必须在 FarmManager 之后。）
3) event_bus.gd：加 signal weather_changed(weather_id: int, weather_name: String)
4) game_manager.gd new_game()：FarmManager.new_game() 后加 WeatherManager.new_game()
5) save_manager.gd：save 的 data 加 "weather": WeatherManager.to_save_dict()；
   load 中 FarmManager.load_from_dict 后加 WeatherManager.load_from_dict(data.get("weather", {}))
6) hud.tscn：VBoxContainer 里 MoneyLabel 后加 WeatherLabel(Label)；
   hud.gd：@onready weather_label，_ready 连 weather_changed 并主动拉一次当前值，
   _on_weather_changed 里 weather_label.text = "天气: %s" % weather_name

约束：不要修改 farm_manager.gd、time_manager.gd、inventory_manager.gd、数据类、其他 UI 脚本、
除 hud.tscn 外的场景、player.gd。
完成后：新游戏 HUD 显示天气，跨天会变且符合季节，冬天为雪，存读档正确，无报错。
```
