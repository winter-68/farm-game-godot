# T14：商店购买种子

> 通用约束见 [../README.md](../README.md)。

## 任务目标

在商店面板增加「购买」区：列出所有 `buy_price > 0` 的物品（MVP 即绿豆种子），可「买 1 个」，金币足够则扣钱进背包；背包满则退款、不吞钱。

## 需要创建/修改的文件

- 修改 `scenes/ui/shop_ui.tscn`：增加「购买」区（`BuyList` 容器）。
- 修改 `scripts/ui/shop_ui.gd`：增加购买列表刷新与购买逻辑。

## 不要修改的文件

- `event_bus.gd`、autoload（只调用 InventoryManager 公有 API）、数据类、`world.tscn`、其他 UI 脚本、`project.godot`。

## 实现要求

1. `shop_ui.tscn`：在出售区旁/下增加 `VBoxContainer`（`BuyList`）+ 标题「购买」。
2. `shop_ui.gd`：
   - 购买列表数据源：`ItemDatabase.get_all_items()` 中 `buy_price > 0` 的项（固定商品，不依赖背包）。每项一行：物品名 + 单价 + `[买1]` 按钮。
   - `_refresh()` 中一并刷新购买列表（在 `_ready`/打开时也生成一次）。
   - 买 1 逻辑：
     - `if not InventoryManager.try_spend(buy_price): return`（钱不够，什么都不做）
     - `var leftover := InventoryManager.add_item(id, 1)`
     - `if leftover > 0: InventoryManager.add_money(buy_price * leftover)`（背包满，退回未放下部分的钱）
   - 购买后金币（HUD）、背包、商店列表自动刷新。
3. 买价从 `ItemData.buy_price` 读取（种子=20）。

## 验收标准

- 按 **B** 开商店 → 购买区出现「绿豆种子 单价20 [买1]」。
- 金币足够：点「买1」→ 金币 -20、背包种子 +1。
- 金币不足（先把钱花光/卖光再试）：点「买1」→ 无变化、不报错。
- 背包放不下时不会白扣钱（退款）。
- 无报错。

## Godot 测试步骤

1. 按 B 开商店，看购买区。
2. 「买1」→ HUD 金币 -20、开背包看种子 +1。
3. 把金币降到 <20 再点「买1」→ 无变化。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）为商店增加购买功能。

1) 修改 scenes/ui/shop_ui.tscn：增加标题 Label「购买」+ VBoxContainer(名 BuyList)。
2) 修改 scripts/ui/shop_ui.gd：
   - 新增 _refresh_buy(): 清空 BuyList；for item in ItemDatabase.get_all_items():
       if item.buy_price>0: 生成一行 Label(名 单价) + Button"买1"
   - 在原 _refresh() 末尾调用 _refresh_buy()（打开商店时出售/购买都刷新）
   - 买1: 
       if not InventoryManager.try_spend(item.buy_price): return
       var leftover := InventoryManager.add_item(item.item_id, 1)
       if leftover > 0: InventoryManager.add_money(item.buy_price * leftover)  # 背包满退款

约束：只调用 InventoryManager 公有 API，不改其脚本；不要动 event_bus.gd、其他 autoload、
数据类、world.tscn、其他 UI 脚本、project.godot。
完成后：B 开商店可买种子，钱够则-20种子+1，钱不够无变化，背包满退款，无报错。
```
