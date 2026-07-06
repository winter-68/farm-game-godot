# T13：商店 UI + 出售产出物

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现商店面板（可开关），列出背包中**可出售**的物品（`sell_price > 0`），每项可「卖 1 个」/「全卖」，卖出后扣物品、加金币。购买功能在 T14 加。

## 需要创建/修改的文件

- 创建 `scenes/ui/shop_ui.tscn` + `scripts/ui/shop_ui.gd`。
- 修改 `project.godot`：新增输入动作 `toggle_shop`（默认 `B`，键码 66）。
- 修改 `scenes/main/main.tscn`：在 `UI`(CanvasLayer) 下实例化 `shop_ui.tscn`。

## 不要修改的文件

- `event_bus.gd`、autoload（只读/调用 InventoryManager 公有 API，不改脚本）、数据类、`world.tscn`、`hud.gd`、`hotbar.gd`、`inventory_ui.gd`。

## 实现要求

1. `shop_ui.tscn`：`Control` 根（居中 Panel）+ 标题「商店」+ 一个 `VBoxContainer`（`SellList`）用于动态生成出售行 + 关闭按钮。
2. `shop_ui.gd`：
   - `_ready()`：`visible = false`；连接 `EventBus.request_open_shop` → 打开；连接 `EventBus.inventory_changed`、`money_changed` → 若打开则刷新。
   - `_unhandled_input`：按下 `toggle_shop` 翻转显示（打开时刷新）。
   - 打开时刷新「出售列表」：遍历 `InventoryManager.slots`，对 `item_id != &""` 且 `ItemDatabase.get_item(id).sell_price > 0` 的**去重**物品，生成一行：物品名 + 持有数量 + 单价 + `[卖1]` `[全卖]` 按钮。
   - 卖出：`卖1` → `InventoryManager.remove_item(id,1)` 成功后 `add_money(sell_price)`；`全卖` → 数量 n，`remove_item(id,n)` 成功后 `add_money(sell_price*n)`。卖完后列表与 HUD 金币自动刷新。
3. 出售价从 `ItemData.sell_price` 读取（绿豆产出=35）。

## 验收标准

- 收获若干绿豆后，按 **B** 打开商店，出售列表出现「绿豆 ×N 单价35」。
- 点「卖1」→ 数量 -1、金币 +35；点「全卖」→ 全部卖出、金币相应增加、该行消失。
- 背包里没有可卖物品时，列表为空（或提示无可售），不报错。
- 无报错。

## Godot 测试步骤

1. 收获 2~3 个绿豆。
2. 按 B 开商店 → 见绿豆行。
3. 「卖1」验证金币 +35、数量 -1；「全卖」验证清空、金币到位。
4. 再按 B 关闭。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现商店出售面板。

1) project.godot：新增输入动作 toggle_shop 绑定 B（physical_keycode 66）。不改其它动作。
2) scenes/ui/shop_ui.tscn：Control 根（居中 Panel）+ 标题 Label「商店」+ VBoxContainer(名 SellList)
   + 关闭 Button。
3) scripts/ui/shop_ui.gd（挂 Control 根）：
   - _ready: visible=false；连接 EventBus.request_open_shop→_open；
     连接 EventBus.inventory_changed 和 money_changed→若 visible 则 _refresh
   - _unhandled_input: 按下 toggle_shop 翻转 visible（打开时 _refresh）
   - 关闭 Button.pressed → visible=false
   - _refresh(): 清空 SellList；遍历 InventoryManager.slots，收集去重的
     (item_id, 总数量)，仅保留 ItemDatabase.get_item(id).sell_price>0 者；
     每项生成一行(HBoxContainer): Label(名 x数量 单价) + Button"卖1" + Button"全卖"
   - 卖1: if InventoryManager.remove_item(id,1): InventoryManager.add_money(sell_price)
   - 全卖: var n=InventoryManager.count_item(id); if InventoryManager.remove_item(id,n):
       InventoryManager.add_money(sell_price*n)
4) 修改 scenes/main/main.tscn：UI(CanvasLayer) 下实例化 shop_ui.tscn。

约束：只调用 InventoryManager 公有 API，不改其脚本；不要动 event_bus.gd、其他 autoload、
数据类、world.tscn、hud.gd、hotbar.gd、inventory_ui.gd。
完成后：B 开关商店，绿豆可卖1/全卖，金币与列表正确刷新，无报错。
```
