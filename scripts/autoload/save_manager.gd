extends Node

const SAVE_DIR := "user://saves"


func _ready() -> void:
	print("[SaveManager] ready")


## Returns the save file path for a slot.
func _slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIR, slot]


## Reports whether a save file exists for the requested slot.
func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_slot_path(slot))


## Writes all current game state to a JSON save file.
func save_game(slot: int) -> void:
	var pos := GameManager.get_player_position()
	var data := {
		"version": 1,
		"time": TimeManager.to_save_dict(),
		"weather": WeatherManager.to_save_dict(),
		"fishing": FishingManager.to_save_dict(),
		"collection": CollectionManager.to_save_dict(),
		"friendship": FriendshipManager.to_save_dict(),
		"inventory": InventoryManager.to_save_dict(),
		"stamina": StaminaManager.to_save_dict(),
		"watering_can": WaterManager.to_save_dict(),
		"farm": FarmManager.to_save_dict(),
		"player": {
			"pos_x": pos.x,
			"pos_y": pos.y,
		},
	}

	var save_dir_absolute := ProjectSettings.globalize_path(SAVE_DIR)
	var dir_error := DirAccess.make_dir_recursive_absolute(save_dir_absolute)
	if dir_error != OK:
		push_warning("[SaveManager] cannot create save directory: %s" % SAVE_DIR)
		return

	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_warning("[SaveManager] cannot open save file")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	EventBus.game_saved.emit(slot)
	print("[SaveManager] saved slot %d" % slot)


## Loads all game state from a JSON save file.
func load_game(slot: int) -> bool:
	if not has_save(slot):
		return false

	var file := FileAccess.open(_slot_path(slot), FileAccess.READ)
	if file == null:
		push_warning("[SaveManager] cannot open save file")
		return false
	var text := file.get_as_text()
	file.close()

	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		push_warning("[SaveManager] bad save")
		return false

	EventBus.save_load_started.emit()
	TimeManager.load_from_dict(data.get("time", {}))
	WeatherManager.load_from_dict(data.get("weather", {}))
	FishingManager.load_from_dict(data.get("fishing", {}))
	CollectionManager.load_from_dict(data.get("collection", {}))
	FriendshipManager.load_from_dict(data.get("friendship", {}))
	InventoryManager.load_from_dict(data.get("inventory", {}))
	StaminaManager.load_from_dict(data.get("stamina", {}))
	WaterManager.load_from_dict(data.get("watering_can", {}))
	FarmManager.load_from_dict(data.get("farm", {}))
	var player_data: Dictionary = data.get("player", {})
	GameManager.set_player_position(Vector2(
		float(player_data.get("pos_x", 0.0)),
		float(player_data.get("pos_y", 0.0))
	))

	EventBus.game_loaded.emit(slot)
	print("[SaveManager] loaded slot %d" % slot)
	return true
