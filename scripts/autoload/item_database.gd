extends Node

const ITEMS_PATH := "res://resources/items"
const CROPS_PATH := "res://resources/crops"
const FISH_PATH := "res://resources/fish"
const FISH_ITEM_IDS := {
	"crucian": &"fish_crucian",
	"carp": &"fish_carp",
	"bass": &"fish_bass",
	"goldfish": &"fish_goldfish",
	"pufferfish": &"fish_pufferfish",
}

var _items: Dictionary = {}
var _crops: Dictionary = {}
var _fish_by_item_id: Dictionary = {}
var _fish_item_id_by_name: Dictionary = {}


func _ready() -> void:
	_load_items()
	_load_crops()
	_load_fish()
	print("[ItemDatabase] loaded %d items, %d crops, %d fish" % [_items.size(), _crops.size(), _fish_by_item_id.size()])


## Returns an item definition by ID, or null when it is unknown.
func get_item(id: StringName) -> ItemData:
	return _items.get(id) as ItemData


## Returns a crop definition by ID, or null when it is unknown.
func get_crop(id: StringName) -> CropData:
	return _crops.get(id) as CropData


func get_fish(item_id: StringName) -> Resource:
	return _fish_by_item_id.get(item_id)


func get_bait(bait_id: StringName) -> Resource:
	return BaitDatabase.get_bait(bait_id)


func get_rod(rod_id: StringName) -> Resource:
	return RodDatabase.get_rod(rod_id)


func get_fish_item_id(fish_data: Resource) -> StringName:
	if fish_data == null:
		return &""
	for item_id in _fish_by_item_id.keys():
		if _fish_by_item_id[item_id] == fish_data:
			return item_id
	return StringName(_fish_item_id_by_name.get(String(fish_data.fish_name), ""))


func get_all_fish_items() -> Array:
	var result := []
	for item in _items.values():
		if item != null and item.type == ItemData.Type.FISH:
			result.append(item)
	return result


## Returns all loaded item definitions.
func get_all_items() -> Array:
	return _items.values()


func _load_items() -> void:
	for path in _get_resource_paths(ITEMS_PATH):
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_warning("[ItemDatabase] Failed to load item resource: %s" % path)
			continue
		if not resource is ItemData:
			push_warning("[ItemDatabase] Resource is not ItemData: %s" % path)
			continue
		var item := resource as ItemData
		if item.item_id == &"":
			push_warning("[ItemDatabase] Item has an empty id: %s" % path)
			continue
		if _items.has(item.item_id):
			push_warning("[ItemDatabase] Duplicate item id '%s': %s" % [item.item_id, path])
			continue
		_items[item.item_id] = item


func _load_crops() -> void:
	for path in _get_resource_paths(CROPS_PATH):
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_warning("[ItemDatabase] Failed to load crop resource: %s" % path)
			continue
		if not resource is CropData:
			push_warning("[ItemDatabase] Resource is not CropData: %s" % path)
			continue
		var crop := resource as CropData
		if crop.crop_id == &"":
			push_warning("[ItemDatabase] Crop has an empty id: %s" % path)
			continue
		if _crops.has(crop.crop_id):
			push_warning("[ItemDatabase] Duplicate crop id '%s': %s" % [crop.crop_id, path])
			continue
		_crops[crop.crop_id] = crop


func _load_fish() -> void:
	for path in _get_resource_paths(FISH_PATH):
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_warning("[ItemDatabase] Failed to load fish resource: %s" % path)
			continue
		if not resource is FishData:
			push_warning("[ItemDatabase] Resource is not FishData: %s" % path)
			continue
		var base_name := path.get_file().get_basename()
		var item_id: StringName = FISH_ITEM_IDS.get(base_name, &"")
		if item_id == &"" or not _items.has(item_id):
			push_warning("[ItemDatabase] Fish has no matching item: %s" % path)
			continue
		_fish_by_item_id[item_id] = resource
		_fish_item_id_by_name[String(resource.fish_name)] = item_id


func _get_resource_paths(directory_path: String) -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_warning("[ItemDatabase] Could not open directory: %s" % directory_path)
		return paths
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() == "tres":
			paths.append(directory_path.path_join(file_name))
	paths.sort()
	return paths
