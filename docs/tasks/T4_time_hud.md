# T4：时间系统 TimeManager + HUD 显示

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现游戏内时间推进（分/时/天），发 `time_changed`/`day_passed` 信号，提供 `advance_to_next_day()`（睡觉）；创建 HUD 显示「第 X 天 HH:MM」与金币占位；接一个「睡觉」交互（MVP 先用调试：按 `interact` 睡觉）。

## 需要创建/修改的文件

- 修改 `scripts/autoload/time_manager.gd`：实现时钟与天数、`to_save_dict/load_from_dict`。
- 创建 `scenes/ui/hud.tscn` + `scripts/ui/hud.gd`。
- 修改 `scenes/main/main.tscn`：加 `CanvasLayer/UI` 并实例化 `hud.tscn`。
- 睡觉调试逻辑：在 `hud.gd`（或 HUD 上的小脚本）监听 `interact` 直接调 `TimeManager.advance_to_next_day()`，并注释「T11 收获接入后需改为仅限床/调试键」。

## 不要修改的文件

- `event_bus.gd`（已含所需信号）、其他管理器、数据类、`world.tscn`、`player.gd`。

## 实现要求

1. 时间参数：`seconds_per_game_minute`（导出，默认 `0.5` 真实秒/游戏分钟）。用累加 `delta` 或 `Timer` 推进 `minute`。
2. `minute` 满 60 进 `hour`。MVP 可不做自动强制睡觉，仅手动睡觉。
3. 每次分钟变化 emit `time_changed(day,hour,minute)`；`advance_to_next_day()` 让 `day+1`、时间重置为早晨（6:00），先 emit `day_passed(day)` 再 emit `time_changed`。
4. `HUD` 监听 `time_changed` 更新时间标签、`day_passed` 更新天数、`money_changed` 更新金币（金币系统未做，先显示 0）。
5. `to_save_dict()` 返回 `{day,hour,minute}`；`load_from_dict()` 反向设置并 emit 一次 `time_changed`。`_ready()` 里 emit 一次初始 `time_changed`。

## 验收标准

- 运行后 HUD 时间在走（分钟递增），显示「第1天 06:00」样式。
- 触发睡觉后天数 +1、时间回到早晨，`day_passed` 被发出。
- 无报错。

## Godot 测试步骤

1. 运行观察 HUD 时间递增。
2. 按 `interact`（睡觉调试）→ 天数 +1、时间重置。
3. 控制台确认 `day_passed`（可临时在 TimeManager 打印）。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3）实现时间系统与 HUD。

1) 修改 scripts/autoload/time_manager.gd (extends Node)：
   - 变量 day:int=1, hour:int=6, minute:int=0
   - @export seconds_per_game_minute:float=0.5（真实秒/游戏分钟，可调）
   - 用累加 delta 或 Timer 推进 minute；满60进hour；每次分钟变化
     EventBus.time_changed.emit(day,hour,minute)
   - advance_to_next_day()：day+=1; hour=6; minute=0; 先 EventBus.day_passed.emit(day)
     再 time_changed.emit(day,hour,minute)
   - to_save_dict()->{day,hour,minute}；load_from_dict(d)：赋值并 emit 一次 time_changed
   - _ready 里 emit 一次初始 time_changed
2) scenes/ui/hud.tscn (Control) + scripts/ui/hud.gd：
   - Label 显示 "第 %d 天  %02d:%02d"；Label 显示 "金币: %d"
   - _ready 连接 EventBus.time_changed/day_passed/money_changed 更新显示
     (money 尚未实现，先默认0)
3) 修改 scenes/main/main.tscn：新增 CanvasLayer 名 UI，在其下实例化 hud.tscn。
4) 睡觉(调试)：在 hud.gd 的 _unhandled_input 中，Input.is_action_just_pressed("interact")
   调用 TimeManager.advance_to_next_day()。加注释：// TODO(T11): 收获接入后改为仅床/调试键触发。

约束：不要修改 event_bus.gd 或其它管理器/数据类/world.tscn/player.gd。运行后 HUD 时间递增，
按 interact 天数+1并重置到早晨，无报错。
```
