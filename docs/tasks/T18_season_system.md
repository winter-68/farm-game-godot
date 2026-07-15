# T18：季节系统（四季循环 + HUD 显示）

> 通用约束见 [../README.md](../README.md)。批次 D 第 1 个任务。

## 任务目标

实现四季循环：春/夏/秋/冬，每季 28 天，跨季自动切换并 emit `season_changed`。HUD 显示当前季节（中文）。起始季节为**春季第 1 天**。

## 需要创建/修改的文件

- 修改 `scripts/autoload/time_manager.gd`：增加 `season` 字段、季节计算、`season_changed` 信号。
- 修改 `scripts/autoload/event_bus.gd`：增加 `season_changed(season_name: String)` 信号。
- 修改 `scripts/ui/hud.gd`：显示季节（如"春季 第 3 天"），监听 `season_changed`。
- 修改 `scenes/ui/hud.tscn`：调整时间 Label 布局或增加季节 Label（自行决定）。

## 不要修改的文件

- `game_manager.gd`、`inventory_manager.gd`、`farm_manager.gd`、`save_manager.gd`、数据类、其他 UI 脚本、世界场景、player。

## 实现要求

1. **`TimeManager`**：
   - 常量：`const SEASON_NAMES := ["春", "夏", "秋", "冬"]`；`const DAYS_PER_SEASON := 28`
   - 新增字段：`var season: int = 0`（0=春, 1=夏, 2=秋, 3=冬）
   - `new_game()`：`season = 0`（春季第 1 天）
   - `advance_to_next_day()`：跨天后检查 `if (day - 1) % DAYS_PER_SEASON == 0 and day > 1`（每 28 天一次，从第 29 天开始），则 `season = (season + 1) % 4`；emit `EventBus.season_changed.emit(SEASON_NAMES[season])`
   - `get_season_name() -> String`：返回 `SEASON_NAMES[season]`
   - `get_day_in_season() -> int`：返回 `((day - 1) % DAYS_PER_SEASON) + 1`（季内第几天，1~28）
   - `to_save_dict`：增加 `"season": season`
   - `load_from_dict`：读 `season = d.get("season", 0)`
2. **`EventBus`**：
   - 新增 `signal season_changed(season_name: String)`
3. **`hud.gd`**：
   - `_ready` 增加 `EventBus.season_changed.connect(_on_season_changed)`
   - `_on_time_changed`：改显示格式为 `"%s 第 %d 天  %02d:%02d" % [TimeManager.get_season_name(), TimeManager.get_day_in_season(), hour, minute]`
   - `_on_season_changed(_season_name)`：刷新一次显示（调 `_on_time_changed`）

## 验收标准

- 新游戏启动 → HUD 显示"春 第 1 天 06:00"、金币 500。
- 睡觉 27 次 → "春 第 28 天"；再睡一次 → "夏 第 1 天"，无报错。
- 继续睡到第 29/57/85 天 → 夏→秋→冬→春 循环正确。
- 按 K 存档 → 打开 JSON 确认有 `"season"`；按 L 读档 → 季节/天数恢复正确。
- 无报错。

## Godot 测试步骤

1. F5 新游戏 → HUD 显示"春 第 1 天"。
2. 连续睡觉 28 次 → 确认跨到"夏 第 1 天"。
3. K 存档 → L 读档 → 核对季节/天数。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现四季循环。

1) scripts/autoload/event_bus.gd：增加 signal season_changed(season_name: String)
2) scripts/autoload/time_manager.gd：
   const SEASON_NAMES := ["春", "夏", "秋", "冬"]
   const DAYS_PER_SEASON := 28
   var season: int = 0
   func new_game(): 增加 season=0
   func get_season_name()->String: return SEASON_NAMES[season]
   func get_day_in_season()->int: return ((day-1)%DAYS_PER_SEASON)+1
   func advance_to_next_day(): 跨天后增加:
     if (day-1)%DAYS_PER_SEASON==0 and day>1:
       season=(season+1)%4
       EventBus.season_changed.emit(SEASON_NAMES[season])
   to_save_dict: 增加 "season":season
   load_from_dict: season=d.get("season",0)
3) scripts/ui/hud.gd：
   _ready 增加 EventBus.season_changed.connect(_on_season_changed)
   _on_time_changed 改为:
     time_label.text="%s 第 %d 天  %02d:%02d" % [TimeManager.get_season_name(),
       TimeManager.get_day_in_season(), hour, minute]
   新增 func _on_season_changed(_s): _on_time_changed(TimeManager.day,
     TimeManager.hour, TimeManager.minute)
4) scenes/ui/hud.tscn：若 time_label 太窄，增加 custom_minimum_size.x

约束：不要修改 game_manager.gd、inventory_manager.gd、farm_manager.gd、
save_manager.gd、数据类、其他 UI 脚本、世界场景、player。
完成后：新游戏"春 第1天"，睡28次跨夏，存读档季节正确，无报错。
```
