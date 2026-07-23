class_name NPCController
extends CharacterBody2D

const SPEED := 60.0
const ARRIVE_DISTANCE := 2.0
const MIN_WAIT_SECONDS := 3.0
const MAX_WAIT_SECONDS := 5.0
const TARGET_PICK_ATTEMPTS := 16
const STUCK_SECONDS := 0.55
const STUCK_DISTANCE := 0.8
const ArtDefaults := preload("res://scripts/art/art_defaults.gd")

@export var npc_data: Resource:
	set(value):
		npc_data = value
		if is_node_ready():
			_apply_data()

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_label: Label = $PromptLabel
@onready var wander_timer: Timer = $Timer

var _rng := RandomNumberGenerator.new()
var _target_position: Vector2 = Vector2.ZERO
var _has_target := false
var _player_near := false
var _dialogue_active := false
var _facing := Vector2i.DOWN
var _walk_frame_index := 0
var _walk_frame_timer := 0.0
var _last_position := Vector2.ZERO
var _stuck_timer := 0.0


func _ready() -> void:
	_rng.randomize()
	wander_timer.timeout.connect(_on_timer_timeout)
	EventBus.dialogue_active_changed.connect(_on_dialogue_active_changed)
	prompt_label.visible = false
	_last_position = global_position
	_apply_data()
	_start_wait()


func _physics_process(_delta: float) -> void:
	_update_player_near()
	if not _has_target:
		velocity = Vector2.ZERO
		_update_sprite(Vector2.ZERO, _delta)
		return

	var to_target := _target_position - global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		velocity = Vector2.ZERO
		_has_target = false
		_update_sprite(Vector2.ZERO, _delta)
		_start_wait()
		return

	velocity = to_target.normalized() * SPEED
	_update_facing(velocity)
	_update_sprite(velocity, _delta)
	move_and_slide()
	_update_stuck_state(_delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or _dialogue_active or not event.is_action_pressed("dialogue_continue"):
		return
	EventBus.dialogue_requested.emit(npc_data)
	prompt_label.visible = false
	get_viewport().set_input_as_handled()


func set_npc_data(data: Resource) -> void:
	npc_data = data


func _apply_data() -> void:
	if npc_data == null:
		return
	sprite.texture = ArtDefaults.npc_texture(npc_data)
	sprite.modulate = Color.WHITE if npc_data.get("sprite_texture") != null else npc_data.name_color


func _start_wait() -> void:
	wander_timer.start(_rng.randf_range(MIN_WAIT_SECONDS, MAX_WAIT_SECONDS))


func _on_timer_timeout() -> void:
	_target_position = _pick_target_position()
	_has_target = true
	_last_position = global_position
	_stuck_timer = 0.0


func _pick_target_position() -> Vector2:
	var area: Rect2 = npc_data.move_area if npc_data != null else Rect2()
	if area.size == Vector2.ZERO:
		area = Rect2(global_position - Vector2(48, 32), Vector2(96, 64))
	for _attempt in TARGET_PICK_ATTEMPTS:
		var candidate := Vector2(
			_rng.randf_range(area.position.x, area.position.x + area.size.x),
			_rng.randf_range(area.position.y, area.position.y + area.size.y)
		)
		if _is_position_walkable(candidate):
			return candidate
	return global_position


func _is_position_walkable(world_position: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, world_position)
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	var hits := get_world_2d().direct_space_state.intersect_shape(query, 1)
	return hits.is_empty()


func _update_stuck_state(delta: float) -> void:
	if not _has_target:
		return
	if global_position.distance_to(_last_position) <= STUCK_DISTANCE and is_on_wall():
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0
	_last_position = global_position
	if _stuck_timer >= STUCK_SECONDS:
		_has_target = false
		velocity = Vector2.ZERO
		_stuck_timer = 0.0
		_start_wait()


func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) >= absf(direction.y):
		_facing = Vector2i.RIGHT if direction.x > 0.0 else Vector2i.LEFT
	else:
		_facing = Vector2i.DOWN if direction.y > 0.0 else Vector2i.UP


func _update_sprite(direction: Vector2, delta: float) -> void:
	if npc_data == null:
		return
	sprite.flip_h = false
	if direction == Vector2.ZERO:
		_walk_frame_index = 0
		_walk_frame_timer = 0.0
		var stand_texture := _get_stand_texture()
		sprite.texture = stand_texture if stand_texture != null else ArtDefaults.npc_texture(npc_data)
		return

	var frames := _get_walk_frames()
	if frames.is_empty():
		var stand_texture := _get_stand_texture()
		sprite.texture = stand_texture if stand_texture != null else ArtDefaults.npc_texture(npc_data)
		return

	_walk_frame_timer += delta
	var frame_time := maxf(float(npc_data.get("frame_time")), 0.05)
	if _walk_frame_timer >= frame_time:
		_walk_frame_timer = 0.0
		_walk_frame_index = (_walk_frame_index + 1) % frames.size()
	var frame_texture: Texture2D = frames[_walk_frame_index]
	if frame_texture != null:
		sprite.texture = frame_texture


func _get_stand_texture() -> Texture2D:
	if _facing == Vector2i.UP:
		return npc_data.get("stand_up")
	if _facing == Vector2i.LEFT:
		return npc_data.get("stand_left")
	if _facing == Vector2i.RIGHT:
		return npc_data.get("stand_right")
	var stand_down: Texture2D = npc_data.get("stand_down")
	return stand_down if stand_down != null else npc_data.get("sprite_texture")


func _get_walk_frames() -> Array:
	if _facing == Vector2i.UP:
		return npc_data.get("walk_up") as Array
	if _facing == Vector2i.LEFT:
		return npc_data.get("walk_left") as Array
	if _facing == Vector2i.RIGHT:
		return npc_data.get("walk_right") as Array
	return npc_data.get("walk_down") as Array


func _update_player_near() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	_player_near = player != null and global_position.distance_to(player.global_position) <= 28.0
	prompt_label.visible = _player_near and not _dialogue_active


func _on_dialogue_active_changed(active: bool) -> void:
	_dialogue_active = active
	if active:
		_has_target = false
		wander_timer.stop()
	else:
		_start_wait()
