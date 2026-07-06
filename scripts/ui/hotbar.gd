extends Control

const HOTBAR_ACTIONS: Array[StringName] = [
	&"hotbar_1",
	&"hotbar_2",
	&"hotbar_3",
	&"hotbar_4",
	&"hotbar_5",
	&"hotbar_6",
	&"hotbar_7",
	&"hotbar_8",
	&"hotbar_9",
	&"hotbar_0",
]
const ITEM_SHORT_NAMES := {
	&"tool_hoe": "锄头",
	&"tool_wateringcan": "水壶",
	&"seed_greenbean": "种子",
}
const NORMAL_COLOR := Color(0.12, 0.15, 0.18, 0.9)
const SELECTED_COLOR := Color(0.82, 0.58, 0.16, 0.95)

@onready var slots_container: HBoxContainer = $Slots


func _ready() -> void:
	EventBus.inventory_changed.connect(_refresh)
	EventBus.selected_slot_changed.connect(_on_selected_slot_changed)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	for index in range(HOTBAR_ACTIONS.size()):
		if event.is_action_pressed(HOTBAR_ACTIONS[index]):
			InventoryManager.set_selected(index)
			return


func _refresh() -> void:
	for index in range(slots_container.get_child_count()):
		var panel := slots_container.get_child(index) as PanelContainer
		var label := panel.get_node("Label") as Label
		var slot: Dictionary = InventoryManager.slots[index]
		label.text = _get_slot_text(slot)
		_set_panel_selected(panel, index == InventoryManager.selected_index)


func _on_selected_slot_changed(_index: int) -> void:
	_refresh()


func _get_slot_text(slot: Dictionary) -> String:
	var item_id := StringName(slot.get("item_id", &""))
	if item_id == &"":
		return ""
	var short_name: String = ITEM_SHORT_NAMES.get(item_id, String(item_id))
	var quantity := int(slot.get("quantity", 0))
	return short_name if quantity <= 1 else "%s×%d" % [short_name, quantity]


func _set_panel_selected(panel: PanelContainer, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = SELECTED_COLOR if selected else NORMAL_COLOR
	style.border_width_left = 2 if selected else 1
	style.border_width_top = 2 if selected else 1
	style.border_width_right = 2 if selected else 1
	style.border_width_bottom = 2 if selected else 1
	style.border_color = Color(1.0, 0.88, 0.42, 1.0) if selected else Color(0.35, 0.4, 0.45, 1.0)
	panel.add_theme_stylebox_override("panel", style)
