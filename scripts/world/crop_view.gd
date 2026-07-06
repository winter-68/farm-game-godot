extends Node2D

const CROP_SCENE := preload("res://scenes/world/farm/crop.tscn")

var _ground: TileMapLayer
var _crops: Dictionary = {}
var _crop_ids: Dictionary = {}


func _ready() -> void:
	EventBus.crop_planted.connect(_on_crop_planted)
	EventBus.crop_grew.connect(_on_crop_grew)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.game_loaded.connect(_on_game_loaded)


## Receives the ground layer explicitly for positioning crop views.
func register_ground(ground: TileMapLayer) -> void:
	_ground = ground


func _on_crop_planted(cell: Vector2i, crop_id: StringName) -> void:
	if _ground == null or _crops.has(cell):
		return
	var crop_data: CropData = ItemDatabase.get_crop(crop_id)
	if crop_data == null:
		push_warning("[CropView] Unknown crop id: %s" % crop_id)
		return
	var crop := CROP_SCENE.instantiate() as Node2D
	add_child(crop)
	crop.position = _ground.map_to_local(cell)
	crop.show_stage(crop_data, 0)
	_crops[cell] = crop
	_crop_ids[cell] = crop_id


func _on_crop_grew(cell: Vector2i, stage: int) -> void:
	if not _crops.has(cell) or not _crop_ids.has(cell):
		return
	var crop_data: CropData = ItemDatabase.get_crop(_crop_ids[cell])
	if crop_data == null:
		return
	_crops[cell].show_stage(crop_data, stage)


func _on_crop_harvested(cell: Vector2i, _produce_id: StringName, _amount: int) -> void:
	var tile: FarmTile = FarmManager.tiles.get(cell) as FarmTile
	if tile == null or tile.crop_id == &"":
		if _crops.has(cell):
			_crops[cell].queue_free()
			_crops.erase(cell)
		_crop_ids.erase(cell)
		return
	if not _crops.has(cell) or not _crop_ids.has(cell):
		return
	var crop_data: CropData = ItemDatabase.get_crop(_crop_ids[cell])
	if crop_data != null:
		_crops[cell].show_stage(crop_data, tile.stage)


func _on_game_loaded(_slot: int) -> void:
	for cell in _crops.keys():
		_crops[cell].queue_free()
	_crops.clear()
	_crop_ids.clear()
	if _ground == null:
		return

	for cell: Vector2i in FarmManager.tiles.keys():
		var tile: FarmTile = FarmManager.tiles[cell] as FarmTile
		if tile.crop_id == &"":
			continue
		var crop_data: CropData = ItemDatabase.get_crop(tile.crop_id)
		if crop_data == null:
			continue
		var crop := CROP_SCENE.instantiate() as Node2D
		add_child(crop)
		crop.position = _ground.map_to_local(cell)
		crop.show_stage(crop_data, tile.stage)
		_crops[cell] = crop
		_crop_ids[cell] = tile.crop_id
