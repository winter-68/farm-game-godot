extends Node

const MAX_LEVEL := 10
const LEVEL_THRESHOLDS: Array[int] = [0, 20, 50, 100, 170, 260, 380, 530, 720, 960]

var level: int = 1
var xp: int = 0
var current_rod_id: StringName = &"rod_basic"


func new_game() -> void:
	level = 1
	xp = 0
	current_rod_id = &"rod_basic"
	EventBus.fishing_xp_gained.emit(0, &"new_game")
	EventBus.rod_changed.emit(current_rod_id)


func add_xp(amount: int, source: StringName = &"fish", multiplier: float = 1.0) -> void:
	if amount <= 0:
		return
	var final_amount := maxi(roundi(float(amount) * multiplier), 1)
	xp += final_amount
	EventBus.fishing_xp_gained.emit(final_amount, source)
	while level < MAX_LEVEL and xp >= LEVEL_THRESHOLDS[level]:
		level += 1
		EventBus.fishing_leveled_up.emit(level)


func get_level() -> int:
	return level


func get_xp() -> int:
	return xp


func set_rod(rod_id: StringName) -> void:
	if rod_id == &"" or current_rod_id == rod_id:
		return
	current_rod_id = rod_id
	EventBus.rod_changed.emit(current_rod_id)


func get_current_rod() -> Resource:
	var rod := RodDatabase.get_rod(current_rod_id)
	if rod == null:
		return RodDatabase.get_rod(&"rod_basic")
	return rod


func get_xp_for_next_level() -> int:
	if level >= MAX_LEVEL:
		return 0
	return maxi(LEVEL_THRESHOLDS[level] - xp, 0)


func get_xp_progress() -> float:
	if level >= MAX_LEVEL:
		return 1.0
	var current_threshold := LEVEL_THRESHOLDS[level - 1]
	var next_threshold := LEVEL_THRESHOLDS[level]
	return clampf(float(xp - current_threshold) / float(next_threshold - current_threshold), 0.0, 1.0)


func to_save_dict() -> Dictionary:
	return {
		"fishing_level": level,
		"fishing_xp": xp,
		"current_rod_id": String(current_rod_id),
	}


func load_from_dict(data: Dictionary) -> void:
	level = clampi(int(data.get("fishing_level", 1)), 1, MAX_LEVEL)
	xp = maxi(int(data.get("fishing_xp", 0)), 0)
	current_rod_id = StringName(data.get("current_rod_id", "rod_basic"))
	while level < MAX_LEVEL and xp >= LEVEL_THRESHOLDS[level]:
		level += 1
	EventBus.fishing_xp_gained.emit(0, &"load")
	EventBus.rod_changed.emit(current_rod_id)


func get_xp_reward(fish_data: Resource) -> int:
	if fish_data == null:
		return 0
	var explicit_reward := int(fish_data.xp_reward)
	if explicit_reward > 0:
		return explicit_reward
	var rarity := float(fish_data.rarity)
	if rarity <= 0.3:
		return 5
	if rarity <= 0.6:
		return 10
	if rarity <= 0.8:
		return 20
	return 40
