# T12：背包 UI 面板（Tab 开关）

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现可开关的背包面板：按 `toggle_inventory`（Tab）显示/隐藏，展示全部 24 个槽位（物品名 + 数量），随 `inventory_changed` 实时刷新。纯查看，不做拖拽/整理。

## 需要创建/修改的文件

- 创建 `scenes/ui/inventory_ui.tscn` + `scripts/ui/inventory_ui.gd`。
- 修改 `scenes/main/main.tscn`：在 `UI`(CanvasLayer) 下实例化 `inventory_ui.tscn`。

## 不要修改的文件

- `event_bus.gd`、autoload（只读调用 InventoryManager，不改其脚本）、数据类、`world.tscn`、`hud.gd`、`hotbar.gd`、其他场景脚本。

## 实现要求

1. `inventory_ui.tscn`：`Control` 根（建议半透明背景 `Panel` 居中）+ 一个 `GridContainer`（如 6 列），内含 24 个格子控件（每格：背景 + `Label`）。
2. `inventory_ui.gd`：
   - `_ready()`：默认 `visible = false`；连接 `EventBus.inventory_changed` → 刷新；先刷新一次。
   - `_unhandled_input`：按下 `toggle_inventory` 时翻转 `visible`；打开时刷新一次。
   - 刷新：遍历 `InventoryManager.slots` 全 24 槽，`Label` 显示物品简称 + 数量（空槽留白）。可复用与 hotbar 类似的简称映射（或直接显示 `item_id`）。
3. 不暂停游戏（MVP 简单叠加显示即可）。

## 验收标准

- 运行中按 **Tab** 打开背包，显示 24 格；槽 0 锄头 / 槽 1 水壶 / 槽 2 种子×10，其余留白。
- 再按 Tab 关闭。
- 收获一个绿豆后打开背包，能看到产出物出现在某一格。
- 无报错。

## Godot 测试步骤

1. F5 → 按 Tab 开/关背包。
2. 收获一次作物 → 开背包确认产出物在列。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现背包面板。

1) scenes/ui/inventory_ui.tscn：Control 根（居中半透明 Panel）+ GridContainer(columns=6)，
   放 24 个格子控件，每格含背景 Panel/ColorRect + Label。
2) scripts/ui/inventory_ui.gd（挂 Control 根）：
   - _ready: visible=false；EventBus.inventory_changed.connect(_refresh)；_refresh()
   - _unhandled_input: 按下 toggle_inventory 翻转 visible，打开时 _refresh()
   - _refresh(): 遍历 InventoryManager.slots 全 24 槽，Label 显示物品简称+数量(空槽留白)
     可用简称字典 {tool_hoe:"锄头", tool_wateringcan:"水壶", seed_greenbean:"种子",
     produce_greenbean:"绿豆"}，查不到就显示 item_id
3) 修改 scenes/main/main.tscn：在 UI(CanvasLayer) 下实例化 inventory_ui.tscn。

约束：只读调用 InventoryManager，不改其脚本；不要动 event_bus.gd、其他 autoload、数据类、
world.tscn、hud.gd、hotbar.gd。不暂停游戏。
完成后：Tab 开关背包，显示 24 格及正确内容，收获后产出物可见，无报错。
```
