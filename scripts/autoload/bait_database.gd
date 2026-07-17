extends Node

const BAIT_PATH := "res://resources/bait"

var _bait: Dictionary = {}


func _ready() -> void:
	_load_bait()
	print("[BaitDatabase] loaded %d bait" % _bait.size())


func get_bait(bait_id: StringName) -> Resource:
	return _bait.get(bait_id) as Resource


func get_all_bait() -> Array:
	return _bait.values()


func _load_bait() -> void:
	_bait.clear()
	var directory := DirAccess.open(BAIT_PATH)
	if directory == null:
		push_warning("[BaitDatabase] Could not open directory: %s" % BAIT_PATH)
		return
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() != "tres":
			continue
		var path := BAIT_PATH.path_join(file_name)
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_warning("[BaitDatabase] Failed to load bait resource: %s" % path)
			continue
		if StringName(resource.get("bait_id")) == &"":
			push_warning("[BaitDatabase] Resource is not bait data: %s" % path)
			continue
		var bait: Resource = resource
		if bait.bait_id == &"":
			push_warning("[BaitDatabase] Bait has an empty id: %s" % path)
			continue
		_bait[bait.bait_id] = bait
