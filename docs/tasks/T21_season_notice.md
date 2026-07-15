# T21：季节跨季提示 + 快捷栏新物品显示

> 通用约束见 [../README.md](../README.md)。批次 D 第 4 个任务。

## 任务目标

跨季时弹出提示（如"进入夏季"），3 秒后自动消失。快捷栏显示优化：新物品也能正确显示简称（土豆/番茄/草莓的种子和产出）。

## 需要创建/修改的文件

- 修改 `scripts/ui/hud.gd`：监听 `season_changed`，显示季节提示 Label，3 秒后隐藏。
- 修改 `scenes/ui/hud.tscn`：增加季节提示 Label（初始隐藏）。
- 修改 `scripts/ui/hotbar.gd`：`ITEM_SHORT_NAMES` 增加新物品映射。

## 不要修改的文件

- `event_bus.gd`、管理器脚本、数据类、其他 UI 脚本、场景（除 hud.tscn）、`player.gd`。

## 实现要求

1. **`hud.tscn`**：
   - 新增 `Label`（名 `SeasonNotice`），居中靠上，初始 `visible = false`
   - 字号稍大（如 24~32），半透明背景，z-index 高于其他 UI
2. **`hud.gd`**：
   - `@onready var season_notice: Label = $SeasonNotice`
   - `_ready` 增加 `EventBus.season_changed.connect(_on_season_changed)`
   - `_on_season_changed(season_name: String)`：
     ```gdscript
     season_notice.text = "进入%s季" % season_name
     season_notice.visible = true
     await get_tree().create_timer(3.0).timeout
     season_notice.visible = false
     ```
3. **`hotbar.gd`**：
   - `ITEM_SHORT_NAMES` 增加：
     ```gdscript
     &"seed_potato": "土豆种子",
     &"produce_potato": "土豆",
     &"seed_tomato": "番茄种子",
     &"produce_tomato": "番茄",
     &"seed_strawberry": "草莓种子",
     &"produce_strawberry": "草莓",
     ```

## 验收标准

- 新游戏 → 睡觉 28 次跨夏 → 屏幕中上方出现"进入夏季"，3 秒后消失。
- 跨秋/冬/春都有对应提示。
- 买新作物种子 → 快捷栏显示简称正确（不是 `seed_potato` 原文）。
- 收获新作物 → 快捷栏产出物显示简称正确。
- 无报错。

## Godot 测试步骤

1. F5 → 睡觉 28 次 → 确认"进入夏季"提示出现并 3 秒消失。
2. 买土豆/番茄/草莓种子 → 确认快捷栏显示中文简称。
3. 收获产出 → 快捷栏显示"土豆"/"番茄"/"草莓"。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）增加跨季提示 + 快捷栏新物品显示。

1) scenes/ui/hud.tscn：新增 Label(名 SeasonNotice)，居中靠上，字号 28，半透明背景，
   初始 visible=false
2) scripts/ui/hud.gd：
   @onready var season_notice: Label = $SeasonNotice
   _ready 增加 EventBus.season_changed.connect(_on_season_changed)
   func _on_season_changed(season_name: String):
     season_notice.text = "进入%s季" % season_name
     season_notice.visible = true
     await get_tree().create_timer(3.0).timeout
     season_notice.visible = false
3) scripts/ui/hotbar.gd.ITEM_SHORT_NAMES 增加：
   &"seed_potato":"土豆种子", &"produce_potato":"土豆",
   &"seed_tomato":"番茄种子", &"produce_tomato":"番茄",
   &"seed_strawberry":"草莓种子", &"produce_strawberry":"草莓"

约束：不要修改 event_bus.gd、管理器脚本、数据类、其他 UI 脚本、除 hud.tscn 外的场景、player.gd。
完成后：跨季提示"进入X季"显示 3 秒，快捷栏新物品显示中文简称，无报错。
```
