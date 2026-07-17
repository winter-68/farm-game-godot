extends Node

var _player: Node2D
var _pending_load := false


func _ready() -> void:
	print("[GameManager] ready")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_save"):
		SaveManager.save_game(0)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("debug_load"):
		SaveManager.load_game(0)
		get_viewport().set_input_as_handled()


## Starts a fresh game and switches to the gameplay scene.
func new_game() -> void:
	_pending_load = false
	TimeManager.new_game()
	WeatherManager.new_game()
	FishingManager.new_game()
	CollectionManager.new_game()
	FriendshipManager.new_game()
	InventoryManager.new_game()
	StaminaManager.new_game()
	WaterManager.new_game()
	FarmManager.new_game()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


## Switches to the gameplay scene and requests a deferred load once it is ready.
func continue_game() -> void:
	_pending_load = true
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


## Returns and clears the pending load request.
func consume_pending_load() -> bool:
	var value := _pending_load
	_pending_load = false
	return value


## Registers the active player so save data can include its position.
func register_player(player: Node2D) -> void:
	_player = player


## Returns the active player position, or zero before a player is registered.
func get_player_position() -> Vector2:
	if _player == null:
		return Vector2.ZERO
	return _player.global_position


## Restores the active player position when loading a save.
func set_player_position(pos: Vector2) -> void:
	if _player == null:
		return
	_player.global_position = pos
