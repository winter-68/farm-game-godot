extends Node

const STAGE_THRESHOLDS: Array[int] = [25, 50, 75, 100]

var friendship_data: Dictionary = {}


func new_game() -> void:
	friendship_data.clear()


func get_friendship(npc_name: String) -> int:
	return int(friendship_data.get(npc_name, 0))


func add_friendship(npc_name: String, amount: int) -> void:
	if npc_name.is_empty() or amount == 0:
		return
	var old_value := get_friendship(npc_name)
	var new_value := clampi(old_value + amount, 0, 100)
	friendship_data[npc_name] = new_value
	var old_level := _level_for_value(old_value)
	var new_level := _level_for_value(new_value)
	if new_level > old_level:
		EventBus.friendship_upgraded.emit(npc_name, new_level)


func to_save_dict() -> Dictionary:
	return {
		"friendship_data": friendship_data.duplicate(true),
	}


func load_from_dict(data: Dictionary) -> void:
	friendship_data.clear()
	var saved_data: Dictionary = data.get("friendship_data", data)
	for key in saved_data.keys():
		friendship_data[String(key)] = int(saved_data[key])


func _level_for_value(value: int) -> int:
	var level := 0
	for threshold in STAGE_THRESHOLDS:
		if value >= threshold:
			level += 1
	return level
