extends Node

const ROD_PATH := "res://resources/rod"

var _rods: Dictionary = {}


func _ready() -> void:
	_load_rods()
	print("[RodDatabase] loaded %d rods" % _rods.size())


func get_rod(rod_id: StringName) -> Resource:
	return _rods.get(rod_id) as Resource


func get_all_rods() -> Array:
	return _rods.values()


func _load_rods() -> void:
	_rods.clear()
	var directory := DirAccess.open(ROD_PATH)
	if directory == null:
		push_warning("[RodDatabase] Could not open directory: %s" % ROD_PATH)
		return
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() != "tres":
			continue
		var path := ROD_PATH.path_join(file_name)
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_warning("[RodDatabase] Failed to load rod resource: %s" % path)
			continue
		if StringName(resource.get("rod_id")) == &"":
			push_warning("[RodDatabase] Resource is not rod data: %s" % path)
			continue
		var rod: Resource = resource
		_rods[rod.rod_id] = rod
