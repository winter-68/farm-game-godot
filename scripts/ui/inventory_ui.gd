extends Control

const ArtDefaults := preload("res://scripts/art/art_defaults.gd")
const INVENTORY_SLOT_SCRIPT := preload("res://scripts/ui/inventory_slot.gd")

const ITEM_SHORT_NAMES := {
	&"tool_hoe": "锄头",
	&"tool_wateringcan": "水壶",
	&"seed_greenbean": "绿豆种子",
	&"produce_greenbean": "绿豆",
	&"seed_potato": "土豆种子",
	&"produce_potato": "土豆",
	&"seed_tomato": "番茄种子",
	&"produce_tomato": "番茄",
	&"seed_strawberry": "草莓种子",
	&"produce_strawberry": "草莓",
	&"bait_basic": "基础鱼饵",
	&"bait_quality": "优质鱼饵",
	&"bait_legend": "传说鱼饵",
	&"rod_iron": "铁竿",
	&"rod_gold": "金竿",
	&"food_baked_potato": "烤土豆",
	&"food_tomato_soup": "番茄汤",
	&"food_strawberry_dessert": "草莓甜点",
}
const PANEL_COLOR := Color(0.055, 0.10, 0.07, 0.92)
const SLOT_COLOR := Color(0.075, 0.14, 0.09, 0.94)
const EDIBLE_SLOT_COLOR := Color(0.16, 0.13, 0.065, 0.96)
const GRID_COLUMNS := 6

@onready var panel: PanelContainer = $Panel
@onready var grid: GridContainer = $Panel/MarginContainer/VBoxContainer/Grid
@onready var hint_label: Label = $Panel/MarginContainer/VBoxContainer/Hint


func _ready() -> void:
	visible = false
	$Panel/MarginContainer/VBoxContainer/Title.text = "背包"
	grid.columns = GRID_COLUMNS
	_set_panel_style()
	_ensure_slot_contents()
	for index in range(grid.get_child_count()):
		var slot_panel := grid.get_child(index) as PanelContainer
		slot_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_panel.set_script(INVENTORY_SLOT_SCRIPT)
		slot_panel.set("slot_index", index)
		slot_panel.set("inventory_ui", self)
		slot_panel.gui_input.connect(_on_slot_gui_input.bind(index))
	EventBus.inventory_changed.connect(_refresh)
	EventBus.ui_panel_changed.connect(_on_ui_panel_changed)
	_refresh()


func _input(event: InputEvent) -> void:
	var is_tab := event is InputEventKey and (event as InputEventKey).keycode == KEY_TAB
	if (event.is_action_pressed("toggle_inventory") or is_tab) and not event.is_echo():
		_set_open(not visible)
		get_viewport().set_input_as_handled()


func _set_open(open: bool) -> void:
	visible = open
	if open:
		_refresh()
		UIStateManager.open_panel(&"inventory")
	else:
		UIStateManager.close_panel(&"inventory")


func get_slot_drag_text(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= InventoryManager.slots.size():
		return ""
	var slot: Dictionary = InventoryManager.slots[slot_index]
	var item_id := StringName(slot.get("item_id", &""))
	var item: ItemData = ItemDatabase.get_item(item_id)
	var quantity := int(slot.get("quantity", 0))
	var name: String = ITEM_SHORT_NAMES.get(item_id, item.display_name if item != null else String(item_id))
	return "%s x%d" % [name, quantity]


func swap_slots(from_index: int, to_index: int) -> void:
	if from_index < 0 or to_index < 0:
		return
	if from_index >= InventoryManager.slots.size() or to_index >= InventoryManager.slots.size():
		return
	if from_index == to_index:
		return
	var moved: Dictionary = InventoryManager.slots[from_index]
	InventoryManager.slots[from_index] = InventoryManager.slots[to_index]
	InventoryManager.slots[to_index] = moved
	EventBus.inventory_changed.emit()


func _on_ui_panel_changed(active_panel: StringName) -> void:
	if visible and active_panel != &"inventory":
		visible = false


func _refresh() -> void:
	_ensure_slot_contents()
	hint_label.text = "点击料理食用"
	for index in range(grid.get_child_count()):
		var slot_panel := grid.get_child(index) as PanelContainer
		var box := slot_panel.get_node("Box") as VBoxContainer
		var icon := box.get_node("Icon") as TextureRect
		var label := box.get_node("Label") as Label
		if index >= InventoryManager.slots.size():
			icon.visible = false
			icon.texture = null
			label.text = ""
			_set_slot_style(slot_panel, false)
			continue
		var slot: Dictionary = InventoryManager.slots[index]
		var item_id := StringName(slot.get("item_id", &""))
		var item: ItemData = ItemDatabase.get_item(item_id)
		icon.visible = item != null
		icon.texture = ArtDefaults.item_texture(item) if item != null else null
		label.text = _get_slot_text(slot)
		_set_slot_style(slot_panel, _is_edible_slot(slot))


func _get_slot_text(slot: Dictionary) -> String:
	var item_id := StringName(slot.get("item_id", &""))
	if item_id == &"":
		return ""
	var item: ItemData = ItemDatabase.get_item(item_id)
	var short_name: String = ITEM_SHORT_NAMES.get(item_id, item.display_name if item != null else String(item_id))
	var quantity := int(slot.get("quantity", 0))
	return short_name if quantity <= 1 else "%s×%d" % [short_name, quantity]


func _ensure_slot_contents() -> void:
	for slot_panel in grid.get_children():
		if slot_panel.has_node("Box"):
			continue
		var old_label := slot_panel.get_node_or_null("Label")
		if old_label != null:
			old_label.queue_free()
		var box := VBoxContainer.new()
		box.name = "Box"
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 0)
		slot_panel.add_child(box)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(16, 16)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		box.add_child(icon)

		var label := Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 8)
		box.add_child(label)


func _set_slot_style(slot_panel: PanelContainer, is_edible: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = EDIBLE_SLOT_COLOR if is_edible else SLOT_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.78, 0.55, 0.26, 1.0) if is_edible else Color(0.32, 0.37, 0.42, 1.0)
	slot_panel.add_theme_stylebox_override("panel", style)


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.42, 0.68, 0.42, 1.0)
	panel.add_theme_stylebox_override("panel", style)


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if not visible or not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if not mouse_event.pressed or not mouse_event.double_click or mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	_try_eat_slot(slot_index)
	get_viewport().set_input_as_handled()


func _try_eat_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= InventoryManager.slots.size():
		return
	var slot: Dictionary = InventoryManager.slots[slot_index]
	var item_id := StringName(slot.get("item_id", &""))
	if item_id == &"":
		return
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null or not item.edible:
		return
	if not InventoryManager.remove_item(item_id, 1):
		return
	BuffManager.apply_buff(item.buff_type, item.buff_value, item.buff_duration)


func _is_edible_slot(slot: Dictionary) -> bool:
	var item_id := StringName(slot.get("item_id", &""))
	if item_id == &"":
		return false
	var item: ItemData = ItemDatabase.get_item(item_id)
	return item != null and item.edible
