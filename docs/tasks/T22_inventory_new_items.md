# T22：背包 UI 新物品显示

> 通用约束见 [../README.md](../README.md)。批次 D 第 5 个任务。

## 任务目标

背包面板（Tab）也能正确显示新物品简称（土豆/番茄/草莓的种子和产出），不再显示 `seed_potato` 原文。

## 需要创建/修改的文件

- 修改 `scripts/ui/inventory_ui.gd`：`ITEM_SHORT_NAMES` 增加新物品映射。

## 不要修改的文件

- `event_bus.gd`、管理器脚本、数据类、其他 UI 脚本、场景、`player.gd`。

## 实现要求

1. **`inventory_ui.gd`**：
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

- 买新作物种子 → 按 **Tab** 打开背包 → 显示中文简称（不是 `seed_potato`）。
- 收获产出 → 背包显示"土豆×2"/"番茄×1"/"草莓×1"。
- 无报错。

## Godot 测试步骤

1. F5 → 买土豆种子 → Tab 开背包 → 确认显示"土豆种子×1"。
2. 种植收获 → Tab 看产出显示正确。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）为背包面板增加新物品显示。

1) scripts/ui/inventory_ui.gd.ITEM_SHORT_NAMES 增加：
   &"seed_potato":"土豆种子", &"produce_potato":"土豆",
   &"seed_tomato":"番茄种子", &"produce_tomato":"番茄",
   &"seed_strawberry":"草莓种子", &"produce_strawberry":"草莓"

约束：不要修改 event_bus.gd、管理器脚本、数据类、其他 UI 脚本、场景、player.gd。
完成后：Tab 背包面板显示新物品中文简称，无报错。
```
