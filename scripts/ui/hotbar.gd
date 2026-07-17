extends Control

const ArtDefaults := preload("res://scripts/art/art_defaults.gd")

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
const NORMAL_COLOR := Color(0.12, 0.15, 0.18, 0.9)
const SELECTED_COLOR := Color(0.82, 0.58, 0.16, 0.95)

@onready var slots_container: HBoxContainer = $Slots


func _ready() -> void:
	EventBus.inventory_changed.connect(_refresh)
	EventBus.selected_slot_changed.connect(_on_selected_slot_changed)
	_ensure_slot_contents()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	for index in range(HOTBAR_ACTIONS.size()):
		if event.is_action_pressed(HOTBAR_ACTIONS[index]):
			InventoryManager.set_selected(index)
			return


func _refresh() -> void:
	_ensure_slot_contents()
	for index in range(slots_container.get_child_count()):
		var panel := slots_container.get_child(index) as PanelContainer
		var box := panel.get_node("Box") as VBoxContainer
		var icon := box.get_node("Icon") as TextureRect
		var label := box.get_node("Label") as Label
		var slot: Dictionary = InventoryManager.slots[index]
		var item_id := StringName(slot.get("item_id", &""))
		var item: ItemData = ItemDatabase.get_item(item_id)
		icon.visible = item != null
		icon.texture = ArtDefaults.item_texture(item) if item != null else null
		label.text = _get_slot_text(slot)
		_set_panel_selected(panel, index == InventoryManager.selected_index)


func _on_selected_slot_changed(_index: int) -> void:
	_refresh()


func _get_slot_text(slot: Dictionary) -> String:
	var item_id := StringName(slot.get("item_id", &""))
	if item_id == &"":
		return ""
	var item: ItemData = ItemDatabase.get_item(item_id)
	var short_name: String = ITEM_SHORT_NAMES.get(item_id, item.display_name if item != null else String(item_id))
	var quantity := int(slot.get("quantity", 0))
	return short_name if quantity <= 1 else "%s×%d" % [short_name, quantity]


func _ensure_slot_contents() -> void:
	for panel in slots_container.get_children():
		if panel.has_node("Box"):
			continue
		var old_label := panel.get_node_or_null("Label")
		if old_label != null:
			old_label.queue_free()
		var box := VBoxContainer.new()
		box.name = "Box"
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 0)
		panel.add_child(box)

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


func _set_panel_selected(panel: PanelContainer, selected: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = SELECTED_COLOR if selected else NORMAL_COLOR
	style.border_width_left = 2 if selected else 1
	style.border_width_top = 2 if selected else 1
	style.border_width_right = 2 if selected else 1
	style.border_width_bottom = 2 if selected else 1
	style.border_color = Color(1.0, 0.88, 0.42, 1.0) if selected else Color(0.35, 0.4, 0.45, 1.0)
	panel.add_theme_stylebox_override("panel", style)
