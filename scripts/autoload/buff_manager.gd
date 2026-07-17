extends Node

var move_speed_multiplier: float = 1.0
var _active_buffs: Dictionary = {}


func _process(delta: float) -> void:
	if _active_buffs.is_empty():
		return
	var changed := false
	for buff_type in _active_buffs.keys():
		_active_buffs[buff_type]["remaining"] = float(_active_buffs[buff_type]["remaining"]) - delta
		if float(_active_buffs[buff_type]["remaining"]) <= 0.0:
			_active_buffs.erase(buff_type)
			changed = true
	if changed:
		_recalculate()
		EventBus.buff_changed.emit()


func apply_buff(buff_type: StringName, value: float, duration: float) -> void:
	if buff_type == &"" or duration <= 0.0:
		return
	_active_buffs[buff_type] = {
		"value": value,
		"remaining": duration,
		"duration": duration,
	}
	_recalculate()
	EventBus.buff_changed.emit()


func get_buff_remaining(buff_type: StringName) -> float:
	if not _active_buffs.has(buff_type):
		return 0.0
	return maxf(float(_active_buffs[buff_type]["remaining"]), 0.0)


func has_buff(buff_type: StringName) -> bool:
	return _active_buffs.has(buff_type)


func _recalculate() -> void:
	move_speed_multiplier = 1.0
	if _active_buffs.has(&"move_speed"):
		move_speed_multiplier = maxf(float(_active_buffs[&"move_speed"]["value"]), 0.1)
