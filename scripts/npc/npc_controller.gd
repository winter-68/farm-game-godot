class_name NPCController
extends CharacterBody2D

const SPEED := 60.0
const ARRIVE_DISTANCE := 2.0
const MIN_WAIT_SECONDS := 3.0
const MAX_WAIT_SECONDS := 5.0
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


func _ready() -> void:
	_rng.randomize()
	wander_timer.timeout.connect(_on_timer_timeout)
	EventBus.dialogue_active_changed.connect(_on_dialogue_active_changed)
	prompt_label.visible = false
	_apply_data()
	_start_wait()


func _physics_process(_delta: float) -> void:
	_update_player_near()
	if not _has_target:
		velocity = Vector2.ZERO
		return

	var to_target := _target_position - global_position
	if to_target.length() <= ARRIVE_DISTANCE:
		velocity = Vector2.ZERO
		_has_target = false
		_start_wait()
		return

	velocity = to_target.normalized() * SPEED
	if absf(velocity.x) > 0.1:
		sprite.flip_h = velocity.x < 0.0
	move_and_slide()


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


func _pick_target_position() -> Vector2:
	var area: Rect2 = npc_data.move_area if npc_data != null else Rect2()
	if area.size == Vector2.ZERO:
		area = Rect2(global_position - Vector2(48, 32), Vector2(96, 64))
	return Vector2(
		_rng.randf_range(area.position.x, area.position.x + area.size.x),
		_rng.randf_range(area.position.y, area.position.y + area.size.y)
	)


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
