extends Node2D

const MAP_SIZE := Vector2i(80, 52)
const TILE_SIZE := 16
const GROUND_SOURCE_ID := 0
const GROUND_ATLAS_COORDS := Vector2i(0, 0)

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var farm_layer: TileMapLayer = $FarmLayer
@onready var tile_highlight: Sprite2D = $TileHighlight
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	_build_ground()
	_configure_camera_limits()
	FarmManager.register_layers(ground_layer, farm_layer)
	$CropsRoot.register_ground(ground_layer)
	player.ground_layer = ground_layer
	player.update_target_cell()
	_update_tile_highlight()
	GameManager.register_player(player)
	if GameManager.consume_pending_load():
		call_deferred("_deferred_load")


func _process(_delta: float) -> void:
	_update_tile_highlight()


func _update_tile_highlight() -> void:
	var cell_center := ground_layer.map_to_local(player.target_cell)
	tile_highlight.global_position = ground_layer.to_global(cell_center)


func _deferred_load() -> void:
	SaveManager.load_game(0)


func _build_ground() -> void:
	ground_layer.clear()
	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			ground_layer.set_cell(Vector2i(x, y), GROUND_SOURCE_ID, GROUND_ATLAS_COORDS)


func _configure_camera_limits() -> void:
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = MAP_SIZE.x * TILE_SIZE
	camera.limit_bottom = MAP_SIZE.y * TILE_SIZE
