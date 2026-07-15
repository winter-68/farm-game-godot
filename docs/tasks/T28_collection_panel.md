# T28：收集系统 — 收集面板 UI（图鉴 + 成就）

> 通用约束见 [../README.md](../README.md)。批次 F 第 2 个任务。依赖 [T27](./T27_collection_manager.md)。

## 任务目标

做一个可开关的**收集面板**：上半是**图鉴**（所有 PRODUCE 作物产出的网格，已发现显示名字、未发现显示 `？？？`），下半是**成就列表**（已解锁高亮 ★、未解锁灰色 ☆）。新增按键 **C** 开关。纯读取展示，不改任何数据。

> ⚠️ 键位说明：**用 C 键（physical_keycode 67）**，不要用 J——J（74）已被 `use_tool` 占用会撞键。当前空闲、C=Collection 助记。

## 架构要点

- 面板是表现层：只读 `CollectionManager` 与 `ItemDatabase`、监听 `collection_discovered`/`achievement_unlocked` 在打开时刷新；不写任何状态、不搜别的节点。
- 图鉴条目**动态构建**（按 `type==PRODUCE` 从 `ItemDatabase.get_all_items()` 枚举），成就条目按 `CollectionManager.ACHIEVEMENTS` 顺序动态构建——将来加作物/成就无需改场景。

## 需要创建/修改的文件

- **新建** `scripts/ui/collection_ui.gd`
- **新建** `scenes/ui/collection_ui.tscn`
- 修改 `project.godot`：新增输入动作 `toggle_collection`（键 **C**）
- 修改 `scenes/main/main.tscn`：在 `UI`(CanvasLayer) 下实例化 `CollectionUI`（放在 `ShopUI` 之后）

## 不要修改的文件

- 所有 autoload、数据类、其他 UI 脚本/场景、`player.gd`、`world.tscn`。

## 实现要求

### 1) `project.godot` 输入动作

在 `[input]` 段照 `toggle_inventory` 的格式加（physical_keycode 67 = 字母 C）：
```
toggle_collection={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":16,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":67,"key_label":0,"unicode":0,"location":0,"echo":false,"script":null)
]
}
```

### 2) `scenes/ui/collection_ui.tscn`

```
CollectionUI: Control              # 满屏 anchors 0,0,1,1
└─ Panel: PanelContainer           # 居中（anchors_preset = center，或用容器居中）
   └─ Margin: MarginContainer      # 四边 margin ~8
      └─ VBox: VBoxContainer
         ├─ TitleAlmanac: Label     # 文本「图鉴」
         ├─ AlmanacGrid: GridContainer
         ├─ TitleAch: Label         # 文本「成就」
         └─ AchievementList: VBoxContainer
```
挂上 `collection_ui.gd`。脚本按下面路径取节点，请保持节点名一致。

### 3) `scripts/ui/collection_ui.gd`（新建）

```gdscript
extends Control

const PANEL_COLOR := Color(0.06, 0.07, 0.08, 0.92)
const CARD_COLOR := Color(0.10, 0.12, 0.14, 0.95)
const LOCKED_MODULATE := Color(0.5, 0.5, 0.5, 1.0)
const UNLOCK_COLOR := Color(0.92, 0.82, 0.35, 1.0)

@onready var panel: PanelContainer = $Panel
@onready var almanac_grid: GridContainer = $Panel/Margin/VBox/AlmanacGrid
@onready var achievement_list: VBoxContainer = $Panel/Margin/VBox/AchievementList


func _ready() -> void:
	visible = false
	almanac_grid.columns = 4
	_set_panel_style()
	EventBus.collection_discovered.connect(_on_changed)
	EventBus.achievement_unlocked.connect(_on_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_collection"):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()


# 打开状态下若有新发现/新解锁，实时刷新。信号参数个数不一，用可选参数吃掉。
func _on_changed(_a = null, _b = null) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	_refresh_almanac()
	_refresh_achievements()


func _refresh_almanac() -> void:
	for child in almanac_grid.get_children():
		child.queue_free()
	for item: ItemData in ItemDatabase.get_all_items():
		if item == null or item.type != ItemData.Type.PRODUCE:
			continue
		almanac_grid.add_child(_make_almanac_cell(item))


func _make_almanac_cell(item: ItemData) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(56, 40)
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.set_border_width_all(1)
	style.border_color = Color(0.32, 0.37, 0.42, 1.0)
	card.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if CollectionManager.is_discovered(item.item_id):
		label.text = item.display_name
	else:
		label.text = "？？？"
		label.modulate = LOCKED_MODULATE
	card.add_child(label)
	return card


func _refresh_achievements() -> void:
	for child in achievement_list.get_children():
		child.queue_free()
	for a in CollectionManager.ACHIEVEMENTS:
		achievement_list.add_child(_make_achievement_row(a))


func _make_achievement_row(a: Dictionary) -> Control:
	var unlocked: bool = CollectionManager.is_unlocked(a["id"])
	var row := Label.new()
	var mark := "★" if unlocked else "☆"
	row.text = "%s %s — %s" % [mark, String(a["title"]), String(a["desc"])]
	row.modulate = UNLOCK_COLOR if unlocked else LOCKED_MODULATE
	return row


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_border_width_all(1)
	style.border_color = Color(0.5, 0.56, 0.62, 1.0)
	panel.add_theme_stylebox_override("panel", style)
```

### 4) `scenes/main/main.tscn`

在 `UI`(CanvasLayer) 下、`ShopUI` 之后实例化：
```
[node name="CollectionUI" parent="UI" instance=ExtResource("<新id>_collection")]
```

## 验收标准

- 游戏中按 **C** 打开/再按关闭收集面板。
- 图鉴显示 4 个作物格；**未收获过的显示 `？？？` 灰色**，收获过的显示作物名。
- 成就列表 7 条；已解锁 ★ 高亮、未解锁 ☆ 灰色。
- 打开面板时收获新作物 / 达成新成就 → 面板即时刷新（新格点亮 / 成就变 ★）。
- 关闭面板后游戏正常（移动/种植/商店不受影响）。
- 无报错。

## Godot 测试步骤

1. F5 → 按 C 看面板：图鉴应全是 `？？？`（新档没收获过）、成就全 ☆。
2. 种收一份绿豆 → 按 C → 绿豆格点亮、「初次收获」变 ★。
3. 集齐四种 → 图鉴全亮、「作物学家」★。
4. 反复开关面板，确认不卡输入、不报错。

## 给 Codex 的执行提示词

```
在 Project Sprout（Godot 4.3+）加收集面板 UI（图鉴+成就），按 C 开关。纯读取展示。

1) project.godot [input] 段照 toggle_inventory 格式加 toggle_collection，physical_keycode 67（C）。
   ⚠️ 不要用 J(74)，已被 use_tool 占用。
   （完整块见 T28 任务卡实现要求第 1 节。）
2) 新建 scripts/ui/collection_ui.gd —— 完整内容见 T28 实现要求第 3 节，原样照抄。
3) 新建 scenes/ui/collection_ui.tscn：结构见第 2 节，根 Control「CollectionUI」满屏，
   内含 Panel(PanelContainer 居中)/Margin(MarginContainer)/VBox(VBoxContainer)，
   VBox 下依次 TitleAlmanac(Label「图鉴」)、AlmanacGrid(GridContainer)、
   TitleAch(Label「成就」)、AchievementList(VBoxContainer)。节点名必须与脚本 @onready 路径一致。挂脚本。
4) scenes/main/main.tscn：UI(CanvasLayer) 下、ShopUI 之后实例化 collection_ui.tscn，节点名 CollectionUI。

图鉴按 ItemDatabase.get_all_items() 里 type==PRODUCE 动态建格，成就按 CollectionManager.ACHIEVEMENTS
动态建行；只读 CollectionManager.is_discovered/is_unlocked，不写状态、不搜别的节点。

约束：不要改任何 autoload、数据类、其他 UI 脚本/场景、player.gd、world.tscn。
完成后：按 C 开关面板；图鉴未获显示 ？？？、已获显示名；成就 ★/☆ 区分；打开时新解锁即时刷新；无报错。
```
