extends CharacterBody2D

@export var speed: float = 80.0

var facing: Vector2i = Vector2i.DOWN
var target_cell: Vector2i = Vector2i.ZERO
var ground_layer: TileMapLayer

@onready var facing_indicator: Sprite2D = $FacingIndicator


func _ready() -> void:
	_update_facing_indicator()


func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	velocity = input_direction * speed

	if input_direction != Vector2.ZERO:
		_update_facing(input_direction)
		_update_facing_indicator()

	move_and_slide()
	update_target_cell()


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("interact") and ground_layer != null:
		update_target_cell()
		EventBus.request_harvest.emit(target_cell)
	if Input.is_action_just_pressed("use_tool") and ground_layer != null:
		var item_id := InventoryManager.get_selected_item_id()
		if item_id == &"":
			return
		update_target_cell()
		EventBus.request_use_item.emit(item_id, target_cell)


## Updates the cell directly in front of the player.
func update_target_cell() -> void:
	if ground_layer == null:
		return
	var player_in_ground_space := ground_layer.to_local(global_position)
	target_cell = ground_layer.local_to_map(player_in_ground_space) + facing


func _update_facing(input_direction: Vector2) -> void:
	if absf(input_direction.x) >= absf(input_direction.y):
		facing = Vector2i.RIGHT if input_direction.x > 0.0 else Vector2i.LEFT
	else:
		facing = Vector2i.DOWN if input_direction.y > 0.0 else Vector2i.UP


func _update_facing_indicator() -> void:
	facing_indicator.position = Vector2(facing) * 17.0
