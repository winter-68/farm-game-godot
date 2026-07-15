# T23：经济平衡调整 + 起始金币/背包

> 通用约束见 [../README.md](../README.md)。批次 D 第 6 个任务（收尾）。

## 任务目标

调整起始资源与价格，让多作物玩法更平衡：起始金币降到 **200**，起始不再送种子（让玩家选择买什么），背包扩容到 **30 格**（容纳更多作物产出）。微调部分价格。

## 需要创建/修改的文件

- 修改 `scripts/autoload/inventory_manager.gd`：`_setup_new_game()` 改起始金币/背包大小/初始物品。
- 修改 `scripts/ui/inventory_ui.gd`：`GridContainer.columns` 改为 6（30 格 = 6×5 行）。
- 修改 `scenes/ui/inventory_ui.tscn`：增加 6 个格子（24→30）。
- 可选：微调物品资源价格（根据测试手感）。

## 不要修改的文件

- `event_bus.gd`、其他管理器、数据类定义、其他 UI 脚本、场景（除 inventory_ui.tscn）、`player.gd`。

## 实现要求

1. **`InventoryManager._setup_new_game()`**：
   - 起始金币：`_money = 200`（从 500 降到 200）
   - 背包槽位：`for i in 30`（从 24 改 30）
   - 初始物品：
     - 锄头 ×1（槽 0）
     - 水壶 ×1（槽 1）
     - **删除**绿豆种子×10（让玩家自己买种子）
   - 其余 28 格留空
2. **`inventory_ui.tscn`**：
   - 增加 6 个格子控件（从 24 个到 30 个，照现有格式复制即可）
3. **可选价格微调**（根据测试手感，不强制）：
   - 绿豆种子可降到 15（更便宜，新手友好）
   - 土豆种子可降到 45（春秋主力稍便宜）
   - 其余价格保持 T19 的设定

## 验收标准

- 新游戏 → HUD 显示金币 **200**（不是 500）。
- 快捷栏只有锄头/水壶，**没有种子**。
- 按 **Tab** 打开背包 → 显示 **30 格**（6 列 5 行），槽 0/1 有工具，其余留白。
- 金币 200 足够买 10 个绿豆种子（15×10=150）或 4 个土豆种子（45×4=180），开局可玩。
- 完整回归测试：买种子 → 种植 → 收获 → 出售 → 金币增长，存读档正确。
- 无报错。

## Godot 测试步骤

1. F5 新游戏 → 金币 200、快捷栏只有工具。
2. Tab 背包 → 30 格。
3. B 商店 → 买绿豆/土豆种子（确认价格调整生效）。
4. 完整闭环 → 存读档。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）调整起始资源与背包大小。

1) scripts/autoload/inventory_manager.gd._setup_new_game()：
   _money = 200
   slots.clear(); for i in 30: slots.append({"item_id":&"","quantity":0})
   add_item(&"tool_hoe", 1)
   add_item(&"tool_wateringcan", 1)
   # 删除 add_item(&"seed_greenbean", 10)
2) scenes/ui/inventory_ui.tscn：增加 6 个格子控件（从 24→30，复制既有格式）
3) 可选：修改 resources/items/seed_greenbean.tres buy_price=15；
   resources/items/seed_potato.tres buy_price=45（不强制，看测试手感）

约束：不要修改 event_bus.gd、其他管理器、数据类定义、其他 UI 脚本、除 inventory_ui.tscn 外的场景、player.gd。
完成后：新游戏金币 200、快捷栏无种子、背包 30 格、价格合理可玩，存读档正确，无报错。
```
