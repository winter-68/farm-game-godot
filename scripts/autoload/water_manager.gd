extends Node

const MAX_WATER := 20

var current_water := MAX_WATER


func _ready() -> void:
	_emit_changed()


func has_water() -> bool:
	return current_water > 0


func use_water() -> bool:
	if not has_water():
		return false
	current_water -= 1
	_emit_changed()
	return true


func refill() -> void:
	if current_water == MAX_WATER:
		return
	current_water = MAX_WATER
	_emit_changed()


func new_game() -> void:
	current_water = MAX_WATER
	_emit_changed()


func to_save_dict() -> Dictionary:
	return {"current": current_water}


func load_from_dict(data: Dictionary) -> void:
	current_water = clampi(int(data.get("current", MAX_WATER)), 0, MAX_WATER)
	_emit_changed()


func _emit_changed() -> void:
	EventBus.watering_can_changed.emit(current_water, MAX_WATER)
