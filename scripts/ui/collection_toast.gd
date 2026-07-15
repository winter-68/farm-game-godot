extends Control

const SHOW_SECONDS := 2.0

@onready var label: Label = $Label

var _queue: Array[String] = []
var _showing: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.visible = false
	EventBus.collection_discovered.connect(_on_discovered)
	EventBus.achievement_unlocked.connect(_on_achievement)


func _on_discovered(produce_id: StringName) -> void:
	var item: ItemData = ItemDatabase.get_item(produce_id)
	var produce_name := item.display_name if item != null else String(produce_id)
	_enqueue("发现新作物：%s！" % produce_name)


func _on_achievement(_id: StringName, title: String) -> void:
	_enqueue("达成成就：%s！" % title)


func _enqueue(message: String) -> void:
	_queue.append(message)
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		label.visible = false
		return
	_showing = true
	label.text = _queue.pop_front()
	label.visible = true
	await get_tree().create_timer(SHOW_SECONDS).timeout
	_show_next()
