extends Node2D

const MAP_SIZE := Vector2i(80, 52)
const TILE_SIZE := 16
const GROUND_SOURCE_ID := 0
const GROUND_ATLAS_COORDS := Vector2i(0, 0)
const HOME_SPAWN := Vector2(320, 352)
const KITCHEN_SPAWN := Vector2(320, 352)
const REDLINE_TEXTURE := preload("res://assets/reference/map_collision_redline.jpg")
const REDLINE_CELL_SIZE := 4
const MAP_ART_SIZE := Vector2(1280, 800)

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
	_build_map_colliders()
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


func _build_map_colliders() -> void:
	var image := REDLINE_TEXTURE.get_image()
	if image == null:
		push_error("Unable to read the approved red-line collision map.")
		return
	var root := Node2D.new()
	root.name = "RedlineCollision"
	$ObstacleColliders.add_child(root)
	var source_size := Vector2i(image.get_width(), image.get_height())
	var grid_size := Vector2i(
		ceili(float(source_size.x) / REDLINE_CELL_SIZE),
		ceili(float(source_size.y) / REDLINE_CELL_SIZE)
	)
	var occupied := _build_redline_grid(image, source_size, grid_size)
	var obstacle_index := 0
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			if occupied[y][x] == 0:
				continue
			var rect_size := _consume_grid_rectangle(occupied, Vector2i(x, y), grid_size)
			var source_rect := Rect2i(
				x * REDLINE_CELL_SIZE,
				y * REDLINE_CELL_SIZE,
				rect_size.x * REDLINE_CELL_SIZE,
				rect_size.y * REDLINE_CELL_SIZE
			).intersection(Rect2i(Vector2i.ZERO, source_size))
			var scale := MAP_ART_SIZE / Vector2(source_size)
			var map_rect := Rect2(Vector2(source_rect.position) * scale, Vector2(source_rect.size) * scale)
			_add_box_obstacle(root, "RedlineWall%d" % obstacle_index, map_rect.get_center(), map_rect.size)
			obstacle_index += 1


func _build_redline_grid(image: Image, source_size: Vector2i, grid_size: Vector2i) -> Array:
	var grid: Array = []
	for y in range(grid_size.y):
		var row := PackedByteArray()
		row.resize(grid_size.x)
		for x in range(grid_size.x):
			row[x] = 1 if _grid_cell_has_redline(image, source_size, Vector2i(x, y)) else 0
		grid.append(row)
	return grid


func _grid_cell_has_redline(image: Image, source_size: Vector2i, cell: Vector2i) -> bool:
	var start := cell * REDLINE_CELL_SIZE
	var end := Vector2i(
		mini(start.x + REDLINE_CELL_SIZE, source_size.x),
		mini(start.y + REDLINE_CELL_SIZE, source_size.y)
	)
	for y in range(start.y, end.y):
		for x in range(start.x, end.x):
			var pixel := image.get_pixel(x, y)
			# The approved pen mark is coral red. Requiring a blue component keeps
			# red crops, flowers, and warm roof highlights out of the collision data.
			if pixel.r > 0.78 and pixel.g > 0.08 and pixel.g < 0.55 and pixel.b > 0.12 and pixel.b < 0.62 and pixel.r - pixel.g > 0.34 and pixel.r - pixel.b > 0.30:
				return true
	return false


func _consume_grid_rectangle(grid: Array, origin: Vector2i, grid_size: Vector2i) -> Vector2i:
	var width := 0
	while origin.x + width < grid_size.x and grid[origin.y][origin.x + width] == 1:
		width += 1
	var height := 1
	while origin.y + height < grid_size.y:
		var row_is_solid := true
		for x in range(origin.x, origin.x + width):
			if grid[origin.y + height][x] == 0:
				row_is_solid = false
				break
		if not row_is_solid:
			break
		height += 1
	for y in range(origin.y, origin.y + height):
		for x in range(origin.x, origin.x + width):
			grid[y][x] = 0
	return Vector2i(width, height)


func _add_box_obstacle(root: Node2D, obstacle_name: String, obstacle_position: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = obstacle_name
	body.position = obstacle_position
	body.collision_layer = 1
	body.collision_mask = 1
	root.add_child(body)

	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision_shape.shape = rectangle
	body.add_child(collision_shape)


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
