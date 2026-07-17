extends Node

const TILE_SOURCE_ID := 0
const TILLED_ATLAS_COORDS := Vector2i(1, 0)
const WATERED_ATLAS_COORDS := Vector2i(2, 0)

var tiles: Dictionary = {}

var _ground: TileMapLayer
var _farm: TileMapLayer


func _ready() -> void:
	EventBus.request_use_item.connect(_on_request_use_item)
	EventBus.request_harvest.connect(_on_request_harvest)
	EventBus.day_passed.connect(_on_day_passed)


## Receives the world layers explicitly; this manager never searches the scene tree.
func register_layers(ground: TileMapLayer, farm: TileMapLayer) -> void:
	_ground = ground
	_farm = farm


## Tills a valid ground cell once and records it as persistent runtime state.
func till(cell: Vector2i) -> bool:
	if _ground == null or _farm == null:
		push_warning("[FarmManager] Farm layers have not been registered")
		return false
	if _ground.get_cell_source_id(cell) == -1:
		return false

	var tile: FarmTile = tiles.get(cell) as FarmTile
	if tile != null and tile.tilled:
		return false
	if tile == null:
		tile = FarmTile.new()

	tile.tilled = true
	tiles[cell] = tile
	_farm.set_cell(cell, TILE_SOURCE_ID, TILLED_ATLAS_COORDS, 0)
	EventBus.tile_tilled.emit(cell)
	return true


## Plants one valid seed on an empty tilled cell.
func plant(cell: Vector2i, seed_item_id: StringName) -> bool:
	var tile: FarmTile = tiles.get(cell) as FarmTile
	if tile == null:
		tile = FarmTile.new()
	if not tile.tilled or tile.crop_id != &"":
		return false

	var seed: ItemData = ItemDatabase.get_item(seed_item_id)
	if seed == null or seed.type != ItemData.Type.SEED:
		return false
	var crop_data: CropData = ItemDatabase.get_crop(seed.linked_crop_id)
	if crop_data == null:
		return false
	var allowed := crop_data.allowed_seasons
	if not allowed.is_empty() and not allowed.has(TimeManager.get_season_name()):
		return false
	if not InventoryManager.remove_item(seed_item_id, 1):
		return false

	tile.crop_id = seed.linked_crop_id
	tile.stage = 0
	tile.watered_days = 0
	tile.harvestable = false
	tiles[cell] = tile
	EventBus.crop_planted.emit(cell, tile.crop_id)
	return true


## Waters a tilled cell once for the current day.
func water(cell: Vector2i) -> bool:
	if _ground == null or _farm == null:
		push_warning("[FarmManager] Farm layers have not been registered")
		return false
	var tile: FarmTile = tiles.get(cell) as FarmTile
	if tile == null or not tile.tilled or tile.watered:
		return false

	tile.watered = true
	tiles[cell] = tile
	_farm.set_cell(cell, TILE_SOURCE_ID, WATERED_ATLAS_COORDS, 0)
	EventBus.tile_watered.emit(cell)
	return true


## Waters every tilled tile once, preserving the same idempotent behavior as water().
func water_all_tilled() -> void:
	for cell: Vector2i in tiles.keys():
		var tile: FarmTile = tiles[cell] as FarmTile
		if tile == null or not tile.tilled or tile.watered:
			continue
		tile.watered = true
		if _farm != null:
			_farm.set_cell(cell, TILE_SOURCE_ID, WATERED_ATLAS_COORDS, 0)
		EventBus.tile_watered.emit(cell)


## Harvests a mature crop into inventory and resets or clears its crop state.
func harvest(cell: Vector2i) -> bool:
	var tile: FarmTile = tiles.get(cell) as FarmTile
	if tile == null or tile.crop_id == &"" or not tile.harvestable:
		return false
	var crop: CropData = ItemDatabase.get_crop(tile.crop_id)
	if crop == null:
		return false

	InventoryManager.add_item(crop.produce_item_id, crop.produce_amount)
	if crop.regrows:
		tile.stage = crop.regrow_to_stage
		tile.harvestable = false
		tile.watered_days = 0
	else:
		tile.crop_id = &""
		tile.stage = 0
		tile.harvestable = false
		tile.watered_days = 0
	EventBus.crop_harvested.emit(cell, crop.produce_item_id, crop.produce_amount)
	return true


## Returns farm tile state in save-friendly form.
func to_save_dict() -> Dictionary:
	var out := {}
	for cell: Vector2i in tiles.keys():
		out["%d,%d" % [cell.x, cell.y]] = (tiles[cell] as FarmTile).to_dict()
	return {"tiles": out}


## Restores farm tile state and redraws the farm layer.
func load_from_dict(d: Dictionary) -> void:
	for cell: Vector2i in tiles.keys():
		if _farm != null:
			_farm.erase_cell(cell)
	tiles.clear()

	var saved_tiles: Dictionary = d.get("tiles", {})
	for key in saved_tiles.keys():
		var parts := String(key).split(",")
		if parts.size() != 2:
			continue
		var cell := Vector2i(int(parts[0]), int(parts[1]))
		var tile := FarmTile.from_dict(saved_tiles[key])
		tiles[cell] = tile
		if _farm != null and tile.tilled:
			var atlas := WATERED_ATLAS_COORDS if tile.watered else TILLED_ATLAS_COORDS
			_farm.set_cell(cell, TILE_SOURCE_ID, atlas, 0)


## Clears all farm state for a new game.
func new_game() -> void:
	for cell: Vector2i in tiles.keys():
		if _farm != null:
			_farm.erase_cell(cell)
	tiles.clear()


func _on_day_passed(_new_day: int) -> void:
	for cell: Vector2i in tiles.keys():
		var tile: FarmTile = tiles[cell] as FarmTile

		# Consume yesterday's water before clearing it for the new day.
		if tile.crop_id != &"" and tile.watered:
			var crop: CropData = ItemDatabase.get_crop(tile.crop_id)
			if crop != null and tile.stage < crop.mature_stage():
				tile.watered_days += 1
				if tile.watered_days >= crop.days_per_stage:
					tile.stage += 1
					tile.watered_days = 0
					if tile.stage == crop.mature_stage():
						tile.harvestable = true
					EventBus.crop_grew.emit(cell, tile.stage)

		# Only after growth has been processed, reset water and its visual.
		if tile.watered:
			tile.watered = false
			if tile.tilled and _farm != null:
				_farm.set_cell(cell, TILE_SOURCE_ID, TILLED_ATLAS_COORDS, 0)


func _on_request_harvest(cell: Vector2i) -> void:
	if StaminaManager.can_spend(1.0) and harvest(cell):
		StaminaManager.spend(1.0)


func _on_request_use_item(item_id: StringName, cell: Vector2i) -> void:
	if item_id == &"tool_hoe":
		if StaminaManager.can_spend(4.0) and till(cell):
			StaminaManager.spend(4.0)
		return
	if item_id == &"tool_wateringcan":
		if StaminaManager.can_spend(2.0) and WaterManager.has_water() and water(cell):
			StaminaManager.spend(2.0)
			WaterManager.use_water()
		return
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item != null and item.type == ItemData.Type.SEED:
		if StaminaManager.can_spend(1.0) and plant(cell, item_id):
			StaminaManager.spend(1.0)
		return
	# TODO: Dispatch additional tools in later farming tasks.
