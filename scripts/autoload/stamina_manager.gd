extends Node

const MAX_STAMINA := 100.0

var current_stamina := MAX_STAMINA


func _ready() -> void:
	EventBus.day_passed.connect(_on_day_passed)
	_emit_changed()


func can_spend(amount: float) -> bool:
	return current_stamina >= amount


func spend(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if not can_spend(amount):
		return false
	current_stamina = maxf(0.0, current_stamina - amount)
	_emit_changed()
	return true


func restore_full() -> void:
	current_stamina = MAX_STAMINA
	_emit_changed()


func new_game() -> void:
	restore_full()


func to_save_dict() -> Dictionary:
	return {"current": current_stamina}


func load_from_dict(data: Dictionary) -> void:
	current_stamina = clampf(float(data.get("current", MAX_STAMINA)), 0.0, MAX_STAMINA)
	_emit_changed()


func _on_day_passed(_day: int) -> void:
	restore_full()


func _emit_changed() -> void:
	EventBus.stamina_changed.emit(current_stamina, MAX_STAMINA)
