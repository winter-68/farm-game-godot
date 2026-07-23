extends Node2D

const MAP_SIZE := Vector2i(80, 52)
const TILE_SIZE := 16
const GROUND_SOURCE_ID := 0
const GROUND_ATLAS_COORDS := Vector2i(0, 0)
const HOME_SPAWN := Vector2(320, 352)
const KITCHEN_SPAWN := Vector2(320, 352)

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var farm_layer: TileMapLayer = $FarmLayer
@onready var tile_highlight: Sprite2D = $TileHighlight
@onready var player: CharacterBody2D = $Player
@onready var home_interior: Node2D = $HomeInterior
@onready var kitchen_interior: Node2D = $KitchenInterior

var _current_interior: StringName = &""


func _ready() -> void:
	add_to_group("world_root")
	_build_ground()
	ground_layer.visible = false
	_configure_camera_limits()
	_set_interior_visible(home_interior, false)
	_set_interior_visible(kitchen_interior, false)
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


func enter_interior(interior_id: StringName) -> void:
	if interior_id == &"home":
		_switch_to_interior(home_interior, HOME_SPAWN, interior_id)
	elif interior_id == &"kitchen":
		_switch_to_interior(kitchen_interior, KITCHEN_SPAWN, interior_id)


func exit_interior(return_position: Vector2) -> void:
	_current_interior = &""
	_set_exterior_enabled(true)
	_set_interior_visible(home_interior, false)
	_set_interior_visible(kitchen_interior, false)
	player.global_position = return_position
	player.ground_layer = ground_layer
	player.update_target_cell()
	_configure_camera_limits()
	_update_tile_highlight()


func _update_tile_highlight() -> void:
	if _current_interior != &"":
		tile_highlight.visible = false
		return
	tile_highlight.visible = true
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
	camera.make_current()
	camera.limit_left = -10000000
	camera.limit_top = -10000000
	camera.limit_right = 10000000
	camera.limit_bottom = 10000000


func _switch_to_interior(interior: Node2D, spawn_position: Vector2, interior_id: StringName) -> void:
	_current_interior = interior_id
	_set_exterior_enabled(false)
	_set_interior_visible(home_interior, interior == home_interior)
	_set_interior_visible(kitchen_interior, interior == kitchen_interior)
	player.global_position = spawn_position
	player.ground_layer = null
	_configure_camera_limits()
	_update_tile_highlight()


func _set_exterior_enabled(enabled: bool) -> void:
	for node in [
		farm_layer,
		$CropsRoot,
		$NPCSpawner,
		$Landmarks,
		$ExteriorDecor,
		$ObstacleColliders,
		$ShopEntrance,
		$SleepEntrance,
		$KitchenEntrance,
		$FishingSpotA,
		$FishingSpotB,
		$WaterSourceA,
		$WaterSourceB,
	]:
		if node is CanvasItem:
			(node as CanvasItem).visible = enabled
		elif node == $NPCSpawner:
			for child in node.get_children():
				if child is CanvasItem:
					(child as CanvasItem).visible = enabled
		_set_collision_shapes_enabled(node, enabled)


func _set_interior_visible(interior: Node2D, enabled: bool) -> void:
	interior.visible = enabled
	_set_collision_shapes_enabled(interior, enabled)


func _set_collision_shapes_enabled(node: Node, enabled: bool) -> void:
	if node is CollisionShape2D:
		(node as CollisionShape2D).disabled = not enabled
	for child in node.get_children():
		_set_collision_shapes_enabled(child, enabled)
