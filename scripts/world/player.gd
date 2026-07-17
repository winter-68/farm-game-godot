extends CharacterBody2D

const ArtDefaults := preload("res://scripts/art/art_defaults.gd")

@export var speed: float = 80.0
@export var art_data: Resource

var facing: Vector2i = Vector2i.DOWN
var target_cell: Vector2i = Vector2i.ZERO
var ground_layer: TileMapLayer
var movement_locked := false

var _walk_frame_index := 0
var _walk_frame_timer := 0.0
var _placeholder_texture: Texture2D
var _last_inspected_cell := Vector2i(999999, 999999)

@onready var sprite: Sprite2D = $Sprite2D
@onready var facing_indicator: Sprite2D = $FacingIndicator


func _ready() -> void:
	add_to_group("player")
	_placeholder_texture = ArtDefaults.player_placeholder(art_data)
	EventBus.dialogue_active_changed.connect(_on_dialogue_active_changed)
	EventBus.crop_planted.connect(_on_crop_state_changed)
	EventBus.crop_grew.connect(_on_crop_grew)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	_update_facing_indicator()
	_update_sprite(Vector2.ZERO, 0.0)


func _physics_process(delta: float) -> void:
	if movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_sprite(Vector2.ZERO, delta)
		return

	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	velocity = input_direction * speed * BuffManager.move_speed_multiplier

	if input_direction != Vector2.ZERO:
		_update_facing(input_direction)
		_update_facing_indicator()

	move_and_slide()
	if input_direction != Vector2.ZERO:
		StaminaManager.spend(delta * 0.18)
	_update_sprite(input_direction, delta)
	update_target_cell()


func _unhandled_input(_event: InputEvent) -> void:
	if movement_locked:
		return
	if Input.is_action_just_pressed("interact") and ground_layer != null:
		update_target_cell()
		EventBus.request_harvest.emit(target_cell)
	if Input.is_action_just_pressed("use_tool") and ground_layer != null:
		var item_id := InventoryManager.get_selected_item_id()
		if item_id == &"":
			return
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item != null and item.edible:
			if InventoryManager.remove_item(item_id, 1):
				BuffManager.apply_buff(item.buff_type, item.buff_value, item.buff_duration)
			return
		update_target_cell()
		EventBus.request_use_item.emit(item_id, target_cell)


## Updates the cell directly in front of the player.
func update_target_cell() -> void:
	if ground_layer == null:
		return
	var player_in_ground_space := ground_layer.to_local(global_position)
	target_cell = ground_layer.local_to_map(player_in_ground_space) + facing
	_update_crop_inspection()


func _update_crop_inspection() -> void:
	if target_cell == _last_inspected_cell:
		return
	_last_inspected_cell = target_cell
	var tile: FarmTile = FarmManager.tiles.get(target_cell) as FarmTile
	if tile == null or tile.crop_id == &"":
		EventBus.crop_inspected.emit(&"", 0, 0, 0, 0, false)
		return
	var crop: CropData = ItemDatabase.get_crop(tile.crop_id)
	if crop == null:
		EventBus.crop_inspected.emit(&"", 0, 0, 0, 0, false)
		return
	EventBus.crop_inspected.emit(tile.crop_id, tile.stage, crop.mature_stage(), tile.watered_days, crop.days_per_stage, tile.harvestable)


func _update_facing(input_direction: Vector2) -> void:
	if absf(input_direction.x) >= absf(input_direction.y):
		facing = Vector2i.RIGHT if input_direction.x > 0.0 else Vector2i.LEFT
	else:
		facing = Vector2i.DOWN if input_direction.y > 0.0 else Vector2i.UP


func _update_sprite(input_direction: Vector2, delta: float) -> void:
	if art_data == null:
		_show_placeholder()
		return

	if input_direction == Vector2.ZERO:
		_walk_frame_index = 0
		_walk_frame_timer = 0.0
		var stand_texture: Texture2D = _get_stand_texture()
		if stand_texture != null:
			_apply_texture(stand_texture)
		else:
			_show_placeholder()
		return

	var frames: Array = _get_walk_frames()
	if frames.is_empty():
		var stand_texture: Texture2D = _get_stand_texture()
		if stand_texture != null:
			_apply_texture(stand_texture)
		else:
			_show_placeholder()
		return

	_walk_frame_timer += delta
	var frame_time := maxf(float(art_data.get("frame_time")), 0.01)
	if _walk_frame_timer >= frame_time:
		_walk_frame_timer = 0.0
		_walk_frame_index = (_walk_frame_index + 1) % frames.size()
	var frame_texture: Texture2D = frames[_walk_frame_index]
	if frame_texture != null:
		_apply_texture(frame_texture)
	else:
		_show_placeholder()


func _get_stand_texture() -> Texture2D:
	if facing == Vector2i.UP:
		return art_data.get("stand_up")
	if facing == Vector2i.LEFT:
		return art_data.get("stand_left")
	if facing == Vector2i.RIGHT:
		return art_data.get("stand_right")
	return art_data.get("stand_down")


func _get_walk_frames() -> Array:
	if facing == Vector2i.UP:
		return art_data.get("walk_up") as Array
	if facing == Vector2i.LEFT:
		return art_data.get("walk_left") as Array
	if facing == Vector2i.RIGHT:
		return art_data.get("walk_right") as Array
	return art_data.get("walk_down") as Array


func _apply_texture(texture: Texture2D) -> void:
	sprite.texture = texture
	sprite.modulate = Color.WHITE


func _show_placeholder() -> void:
	sprite.texture = _placeholder_texture
	sprite.modulate = Color.WHITE


func _update_facing_indicator() -> void:
	facing_indicator.position = Vector2(facing) * 17.0


func _on_dialogue_active_changed(active: bool) -> void:
	movement_locked = active


func _on_crop_state_changed(cell: Vector2i, _crop_id: StringName) -> void:
	if cell == target_cell:
		_last_inspected_cell = Vector2i(999999, 999999)
		_update_crop_inspection()


func _on_crop_grew(cell: Vector2i, _stage: int) -> void:
	if cell == target_cell:
		_last_inspected_cell = Vector2i(999999, 999999)
		_update_crop_inspection()


func _on_crop_harvested(cell: Vector2i, _produce_id: StringName, _amount: int) -> void:
	if cell == target_cell:
		_last_inspected_cell = Vector2i(999999, 999999)
		_update_crop_inspection()
