# T29：收集系统 — 解锁提示 toast

> 通用约束见 [../README.md](../README.md)。批次 F 第 3 个任务（收尾）。依赖 [T27](./T27_collection_manager.md)。

## 任务目标

给收集系统加即时反馈：**发现新作物**或**达成新成就**时，屏幕**底部**弹出提示（如「发现新作物：绿豆！」「达成成就：小有收成！」），停留后自动消失。用**队列**串行播放，避免同一帧多个解锁互相覆盖。纯表现。

## 架构要点

- 只监听 `EventBus.collection_discovered` / `achievement_unlocked`；作物名经 `ItemDatabase.get_item(produce_id).display_name` 取。不写状态、不搜别的节点。
- 放屏幕**底部居中**，与顶部的季节提示（HUD）/今日天气（天气 overlay）错开，互不遮挡。
- 读档安全：T27 的 `_loading` 守卫保证读档期间 CollectionManager **不 emit** 这两个信号，所以 toast 不会在读档时误弹——本卡无需再判断。
- 队列串行：多个解锁排队逐条显示，不闪烁不丢失。

## 需要创建/修改的文件

- **新建** `scripts/ui/collection_toast.gd`
- **新建** `scenes/ui/collection_toast.tscn`
- 修改 `scenes/main/main.tscn`：在 `UI`(CanvasLayer) 下实例化 `CollectionToast`（放最后，画在最上层）

## 不要修改的文件

- 所有 autoload、数据类、其他 UI 脚本/场景、`player.gd`、`world.tscn`。

## 实现要求

### 1) `scenes/ui/collection_toast.tscn`

```
CollectionToast: Control        # 满屏 anchors 0,0,1,1；mouse_filter = 2 (Ignore)
└─ Label: Label                 # 底部居中（anchors_preset = 底部宽/居中，y 偏移 ~-24）
                                #   horizontal_alignment = Center；mouse_filter = 2；初始 visible=false
```
挂 `collection_toast.gd`。

### 2) `scripts/ui/collection_toast.gd`（新建）

```gdscript
extends Control

const SHOW_SECONDS := 2.0

@onready var label: Label = $Label

var _queue: Array[String] = []
var _showing: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	EventBus.collection_discovered.connect(_on_discovered)
	EventBus.achievement_unlocked.connect(_on_achievement)


func _on_discovered(produce_id: StringName) -> void:
	var item: ItemData = ItemDatabase.get_item(produce_id)
	var produce_name := item.display_name if item != null else String(produce_id)
	_enqueue("发现新作物：%s！" % produce_name)


func _on_achievement(_id: StringName, title: String) -> void:
	_enqueue("达成成就：%s！" % title)


func _enqueue(msg: String) -> void:
	_queue.append(msg)
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		label.visible = false
		return
	_showing = true
	label.text = _queue.pop_front()
	label.visible = true
	await get_tree().create_timer(SHOW_SECONDS).timeout
	_show_next()
```

### 3) `scenes/main/main.tscn`

在 `UI`(CanvasLayer) 下、所有其它 UI **之后**实例化（保证画在最上层）：
```
[node name="CollectionToast" parent="UI" instance=ExtResource("<新id>_toast")]
```

## 验收标准

- 首次收获某作物 → 底部弹「发现新作物：X！」约 2 秒后消失。
- 同时/连续触发多个解锁（如首次收获既发现作物又达成「初次收获」）→ 提示**依次**显示，不重叠、不丢失。
- 达成成就 → 弹「达成成就：Y！」。
- **读档不弹**任何 toast（靠 T27 守卫）。
- toast 不遮挡 HUD 顶部信息、不拦鼠标（商店/背包/面板仍可点）。
- 无报错。

## Godot 测试步骤

1. F5 新档 → 种收第一份绿豆 → 底部应先后弹「发现新作物：绿豆！」和「达成成就：初次收获！」。
2. 继续收别的作物 → 每种首收都弹一次发现提示。
3. `debug_save` → `debug_load` → 确认**不弹** toast。
4. toast 显示时点开商店/背包 → 确认不被挡、能操作。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）加收集解锁 toast（发现新作物/达成成就 屏幕底部提示）。纯表现。

1) 新建 scripts/ui/collection_toast.gd —— 完整内容见 T29 任务卡实现要求第 2 节，原样照抄。
   用队列串行播放，监听 EventBus.collection_discovered / achievement_unlocked；
   作物名经 ItemDatabase.get_item(produce_id).display_name。
2) 新建 scenes/ui/collection_toast.tscn：根 Control「CollectionToast」满屏 mouse_filter=Ignore；
   子 Label「Label」底部居中、horizontal_alignment=Center、mouse_filter=Ignore、初始 visible=false。挂脚本。
3) scenes/main/main.tscn：UI(CanvasLayer) 下、所有其它 UI 之后实例化，节点名 CollectionToast（画在最上层）。

读档不需特殊处理：CollectionManager 的 _loading 守卫已保证读档期间不 emit 这两个信号。
不写任何状态、不搜别的节点。

约束：不要改任何 autoload、数据类、其他 UI 脚本/场景、player.gd、world.tscn。
完成后：首收/解锁底部弹提示、多个解锁依次不重叠、读档不弹、不挡 HUD 不拦鼠标、无报错。
```
