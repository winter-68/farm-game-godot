# T25：雨天自动浇水

> 通用约束见 [../README.md](../README.md)。批次 E（天气系统）第 2 个任务。依赖 [T24](./T24_weather_system.md)。

## 任务目标

让「雨」天产生实际玩法价值：**雨天自动浇灌当天所有耕地**，玩家无需手动浇水，作物照常跨天成长。这是天气系统唯一的玩法效果（无惩罚、纯正向）。

## 架构要点（这卡的核心，务必理解）

跨天时，`FarmManager._on_day_passed` 的既有逻辑是两步：
1. **先**根据 `tile.watered` 推进作物成长（消耗昨天的水）；
2. **再**把 `tile.watered` 清成 false，视觉复位为「耕地」。

雨水必须在**第 2 步之后**补上，否则会被同一帧的清标记冲掉。因为 Godot 按信号连接顺序回调、autoload 按注册顺序 `_ready`，而 **T24 已把 WeatherManager 注册在 FarmManager 之后** → `WeatherManager._on_day_passed` 天然在 `FarmManager._on_day_passed` 之后执行。所以做法是：

- tile 状态所有权仍归 FarmManager → 给它加公开方法 `water_all_tilled()`；
- WeatherManager 在自己的 `_on_day_passed` 末尾，若今天下雨就调用它。

**不要**在 WeatherManager 里直接读写 `FarmManager.tiles`。

## 需要创建/修改的文件

- 修改 `scripts/autoload/farm_manager.gd`：新增公开方法 `water_all_tilled()`
- 修改 `scripts/autoload/weather_manager.gd`：`_on_day_passed` 末尾按天气调用

## 不要修改的文件

- `event_bus.gd`、`time_manager.gd`、`inventory_manager.gd`、`save_manager.gd`、`game_manager.gd`、数据类、所有 UI、所有场景、`player.gd`。

## 实现要求

### 1) `farm_manager.gd` 新增方法

放在 `water(cell)` 方法附近，复用既有常量 `TILE_SOURCE_ID` / `WATERED_ATLAS_COORDS`：

```gdscript
## Waters every tilled tile for the day. Used by rain weather; idempotent per day.
func water_all_tilled() -> void:
	if _farm == null:
		return
	for cell: Vector2i in tiles.keys():
		var tile: FarmTile = tiles[cell] as FarmTile
		if not tile.tilled or tile.watered:
			continue
		tile.watered = true
		_farm.set_cell(cell, TILE_SOURCE_ID, WATERED_ATLAS_COORDS, 0)
		EventBus.tile_watered.emit(cell)
```

### 2) `weather_manager.gd` 挂钩

> ⚠️ T24 实现采用 StringName 天气 ID（`WEATHER_RAIN` 等）与 `is_rain()` 判定，**没有** `waters_crops()`/枚举。因此这里用 **`is_rain()`**。

在既有 `_on_day_passed` 里追加浇水调用（`_set_weather_for_current_day()` 会先滚天气并发信号）：

```gdscript
func _on_day_passed(_new_day: int) -> void:
	_set_weather_for_current_day()
	if is_rain():
		FarmManager.water_all_tilled()
```

> 说明：
> - 浇水调用**只放在 `_on_day_passed`**，不要放进 `_set_weather_for_current_day()`——后者也被 `new_game()`/`load_from_dict()` 调用，那时不该触发浇水（`water_all_tilled` 有 `_farm == null` 守卫，即使误触发也安全，但语义上只在跨天补雨水最干净）。
> - 仅雨天补水（`is_rain()`）；雪天不浇（冬天无作物）。读档不需要补——`FarmManager.load_from_dict` 已从存档恢复每格 `watered`。当天下雨后新翻的地要下一次下雨才自动浇到，属可接受的小行为。

## 验收标准

- 翻地 + 种一株作物（如春天种绿豆）、**不手动浇水**。
- 反复睡觉跨天，直到遇到雨天：雨天当天所有耕地视觉变为「已浇水」，且该作物能靠雨水正常推进 stage、直至成熟收获。
- 晴/多云/雪天：耕地不会被自动浇水（保持干燥视觉，需手动浇）。
- 手动浇水与雨水不冲突、不报错（已浇过的格子被 `water_all_tilled` 跳过）。
- 存读档后耕地干湿状态正确。
- 无报错。

## Godot 测试步骤

1. F5 新游戏 → 买绿豆种子 → 翻地、播种、**不浇水**。
2. 连续睡觉跨天，观察 HUD 天气；遇到「雨」的当天，确认耕地变蓝（已浇水）。
3. 靠雨水把作物养到成熟并收获（可多睡几天蹭雨天）。
4. 晴天确认耕地干燥、需要手动浇。
5. 存/读档验证干湿状态。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现「雨天自动浇水」。仅改 2 个文件。

1) scripts/autoload/farm_manager.gd：新增公开方法 water_all_tilled()
   —— 完整内容见 T25 任务卡实现要求第 1 节，遍历 tiles，对已翻且未浇的格设 watered=true、
   set_cell 为 WATERED_ATLAS_COORDS、emit tile_watered。

2) scripts/autoload/weather_manager.gd：在既有 _on_day_passed 里、_set_weather_for_current_day() 调用之后追加
   if is_rain():
       FarmManager.water_all_tilled()
   （用 is_rain()，T24 没有 waters_crops()；不要把这两行放进 _set_weather_for_current_day()）

关键顺序：WeatherManager 已注册在 FarmManager 之后，所以其 day_passed 回调在
FarmManager 处理完成长并清掉浇水标记之后运行——雨水才不会被冲掉。不要改这个注册顺序，
不要在 WeatherManager 里直接读写 FarmManager.tiles。

约束：只改 farm_manager.gd 和 weather_manager.gd，其余文件（含存档/其他管理器/UI/场景/player）一律不动。
完成后：雨天当天所有耕地自动变已浇水、作物可只靠雨水成长收获；晴/雪天不自动浇水；手动浇水不冲突；存读档正确；无报错。
```
