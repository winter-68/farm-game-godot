extends Node

const ITEMS_PATH := "res://resources/items"
const CROPS_PATH := "res://resources/crops"

var _items: Dictionary = {}
var _crops: Dictionary = {}


func _ready() -> void:
	_load_items()
	_load_crops()
	print("[ItemDatabase] loaded %d items, %d crops" % [_items.size(), _crops.size()])


## Returns an item definition by ID, or null when it is unknown.
func get_item(id: StringName) -> ItemData:
	return _items.get(id) as ItemData


## Returns a crop definition by ID, or null when it is unknown.
func get_crop(id: StringName) -> CropData:
	return _crops.get(id) as CropData


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
