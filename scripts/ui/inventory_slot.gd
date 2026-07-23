class_name InventorySlot
extends PanelContainer

var slot_index: int = -1
var inventory_ui: Control


func _get_drag_data(_at_position: Vector2) -> Variant:
	if inventory_ui == null or not inventory_ui.visible:
		return null
	if slot_index < 0 or slot_index >= InventoryManager.slots.size():
		return null
	var slot: Dictionary = InventoryManager.slots[slot_index]
	if StringName(slot.get("item_id", &"")) == &"":
		return null
	var preview := Label.new()
	preview.text = inventory_ui.get_slot_drag_text(slot_index)
	preview.add_theme_font_size_override("font_size", 10)
	preview.modulate = Color(1.0, 0.95, 0.7, 0.95)
	set_drag_preview(preview)
	return {"slot_index": slot_index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("slot_index") and int(data["slot_index"]) != slot_index


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if inventory_ui == null or not _can_drop_data(_at_position, data):
		return
	inventory_ui.swap_slots(int(data["slot_index"]), slot_index)
