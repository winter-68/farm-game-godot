class_name FarmTile extends RefCounted

var tilled: bool = false
var watered: bool = false
var crop_id: StringName = &""
var stage: int = 0
var watered_days: int = 0
var harvestable: bool = false


## Converts this tile's state into save-friendly data.
func to_dict() -> Dictionary:
	return {
		"tilled": tilled,
		"watered": watered,
		"crop_id": String(crop_id),
		"stage": stage,
		"watered_days": watered_days,
		"harvestable": harvestable,
	}


## Creates a farm tile from save data, using defaults for missing fields.
static func from_dict(d: Dictionary) -> FarmTile:
	var tile := FarmTile.new()
	tile.tilled = bool(d.get("tilled", false))
	tile.watered = bool(d.get("watered", false))
	tile.crop_id = StringName(d.get("crop_id", ""))
	tile.stage = int(d.get("stage", 0))
	tile.watered_days = int(d.get("watered_days", 0))
	tile.harvestable = bool(d.get("harvestable", false))
	return tile
