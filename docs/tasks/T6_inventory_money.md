# T6：InventoryManager（金币 + 背包槽 + 选中项）

> 通用约束见 [../README.md](../README.md)。

## 任务目标

实现 `InventoryManager`：全局金币、固定容量背包槽、当前选中槽位，以及增删物品/花钱的 API 和存档接口。设置一份**新游戏初始状态**（起始金币 + 起始工具/种子）以便后续任务测试。HUD 金币由本任务真正驱动。

## 需要创建/修改的文件

- 修改 `scripts/autoload/inventory_manager.gd`：实现全部逻辑。
- （无需改 HUD，`hud.gd` 已监听 `money_changed`；本任务通过初始化 emit 让它显示起始金币。）

## 不要修改的文件

- `event_bus.gd`、其他管理器、数据类、任何场景、`project.godot`、`hud.gd`。

## 实现要求

1. 状态：
   - `const SLOT_COUNT := 24`
   - `var money: int = 0`
   - `var slots: Array = []`（每槽为 `{ "item_id": StringName, "quantity": int }`，空槽 `{ &"", 0 }`）
   - `var selected_index: int = 0`
2. API（公有方法写注释）：
   - `add_item(item_id, amount) -> int`：先堆入已有同类未满栈（受 `ItemData.max_stack`、`stackable` 限制），再填空槽；返回**未放下的剩余数量**（0 表示全部放下）。放入后 emit `inventory_changed`。
   - `remove_item(item_id, amount) -> bool`：数量足够则扣除并返回 true，否则不动返回 false。变动后 emit `inventory_changed`。
   - `count_item(item_id) -> int`、`has_item(item_id, amount) -> bool`
   - `add_money(amount)`：改 `money` 并 emit `money_changed(money)`。
   - `try_spend(amount) -> bool`：够则扣钱返回 true 并 emit，否则返回 false。
   - `get_selected() -> Dictionary`（返回选中槽）、`get_selected_item_id() -> StringName`
   - `set_selected(index)`：夹取到 `[0, SLOT_COUNT)`，变化时 emit `selected_slot_changed(selected_index)`。
3. 新游戏初始化 `_setup_new_game()`（`_ready()` 调用）：
   - `money = 500`
   - 槽 0：`tool_hoe` ×1；槽 1：`tool_wateringcan` ×1；槽 2：`seed_greenbean` ×10。
   - 初始化后 emit `money_changed`、`inventory_changed`、`selected_slot_changed(0)`。
4. 存档：`to_save_dict()` 返回 `{ money, selected_index, slots }`（slots 里 item_id 存为 String）；`load_from_dict(d)` 还原并 emit 上述三个信号。
5. 依赖 `ItemDatabase.get_item()` 读取 `max_stack/stackable`；查不到的 id 用 `push_warning` 且不崩溃。

## 验收标准

- 运行后 HUD 金币显示 `500`。
- 通过 Remote 调试台验证：
  - `InventoryManager.count_item(&"seed_greenbean")` == 10
  - `InventoryManager.add_money(50)` 后 HUD 变 550
  - `InventoryManager.get_selected_item_id()` == `&"tool_hoe"`
- 无报错。

## Godot 测试步骤

1. F5，确认 HUD 金币=500。
2. 打开 Remote（运行时场景树）→ 底部表达式栏执行上面几条验证。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）实现 scripts/autoload/inventory_manager.gd（extends Node）。

状态：
- const SLOT_COUNT := 24
- var money: int = 0
- var slots: Array = []   # 每槽 { "item_id": StringName, "quantity": int }，空槽 {&"",0}
- var selected_index: int = 0

方法（均加简短注释）：
- _ready(): _setup_new_game()
- _setup_new_game(): 初始化 slots 为 SLOT_COUNT 个空槽；money=500；
    槽0=tool_hoe x1, 槽1=tool_wateringcan x1, 槽2=seed_greenbean x10；
    emit EventBus.money_changed(money)、inventory_changed()、selected_slot_changed(0)
- add_item(item_id:StringName, amount:int)->int：按 ItemData 的 stackable/max_stack
    先堆已有栈再填空槽，返回未放下剩余；变动后 emit inventory_changed
- remove_item(item_id, amount)->bool：不足返回 false 不改动；足够则扣除 emit inventory_changed
- count_item(item_id)->int; has_item(item_id, amount)->bool
- add_money(amount): money+=amount; emit money_changed(money)
- try_spend(amount)->bool: 不足 false；足够扣钱 emit money_changed 返回 true
- get_selected()->Dictionary; get_selected_item_id()->StringName
- set_selected(index): clamp 到 [0,SLOT_COUNT)，变化时 emit selected_slot_changed(selected_index)
- to_save_dict()->{money, selected_index, slots(item_id 存 String)}
- load_from_dict(d): 还原并 emit money_changed/inventory_changed/selected_slot_changed

用 ItemDatabase.get_item() 取 max_stack/stackable；查不到的 id 用 push_warning 不崩溃。

约束：只改 inventory_manager.gd。不要动 event_bus.gd、其他管理器、数据类、任何场景、
project.godot、hud.gd。完成后 HUD 金币应显示 500，且上述 Remote 验证通过，无报错。
```
