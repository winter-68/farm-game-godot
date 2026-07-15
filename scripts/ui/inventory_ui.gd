extends Control

const ITEM_SHORT_NAMES := {
	&"tool_hoe": "锄头",
	&"tool_wateringcan": "水壶",
	&"seed_greenbean": "种子",
	&"produce_greenbean": "绿豆",
	&"seed_potato": "土豆种子",
	&"produce_potato": "土豆",
	&"seed_tomato": "番茄种子",
	&"produce_tomato": "番茄",
	&"seed_strawberry": "草莓种子",
	&"produce_strawberry": "草莓",
}
const PANEL_COLOR := Color(0.06, 0.07, 0.08, 0.82)
const SLOT_COLOR := Color(0.10, 0.12, 0.14, 0.92)
const GRID_COLUMNS := 6

@onready var panel: PanelContainer = $Panel
@onready var grid: GridContainer = $Panel/MarginContainer/VBoxContainer/Grid


func _ready() -> void:
	visible = false
	grid.columns = GRID_COLUMNS
	_set_panel_style()
	EventBus.inventory_changed.connect(_refresh)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	for index in range(grid.get_child_count()):
		var slot_panel := grid.get_child(index) as PanelContainer
		var label := slot_panel.get_node("Label") as Label
		if index >= InventoryManager.slots.size():
			label.text = ""
			continue
		var slot: Dictionary = InventoryManager.slots[index]
		label.text = _get_slot_text(slot)
		_set_slot_style(slot_panel)


func _get_slot_text(slot: Dictionary) -> String:
	var item_id := StringName(slot.get("item_id", &""))
	if item_id == &"":
		return ""
	var short_name: String = ITEM_SHORT_NAMES.get(item_id, String(item_id))
	var quantity := int(slot.get("quantity", 0))
	return short_name if quantity <= 1 else "%s×%d" % [short_name, quantity]


func _set_slot_style(slot_panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.32, 0.37, 0.42, 1.0)
	slot_panel.add_theme_stylebox_override("panel", style)


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.5, 0.56, 0.62, 1.0)
	panel.add_theme_stylebox_override("panel", style)
