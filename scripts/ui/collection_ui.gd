extends Control

const PANEL_COLOR := Color(0.06, 0.07, 0.08, 0.92)
const CARD_COLOR := Color(0.10, 0.12, 0.14, 0.95)
const LOCKED_MODULATE := Color(0.5, 0.5, 0.5, 1.0)
const UNLOCK_COLOR := Color(0.92, 0.82, 0.35, 1.0)

@onready var panel: PanelContainer = $Panel
@onready var almanac_grid: GridContainer = $Panel/Margin/VBox/AlmanacGrid
@onready var achievement_list: VBoxContainer = $Panel/Margin/VBox/AchievementList


func _ready() -> void:
	visible = false
	almanac_grid.columns = 4
	_set_panel_style()
	EventBus.collection_discovered.connect(_on_changed)
	EventBus.achievement_unlocked.connect(_on_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_collection"):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _on_changed(_a = null, _b = null) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	_refresh_almanac()
	_refresh_achievements()


func _refresh_almanac() -> void:
	for child in almanac_grid.get_children():
		child.queue_free()
	for item: ItemData in ItemDatabase.get_all_items():
		if item == null or item.type != ItemData.Type.PRODUCE:
			continue
		almanac_grid.add_child(_make_almanac_cell(item))


func _make_almanac_cell(item: ItemData) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(56, 40)
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.set_border_width_all(1)
	style.border_color = Color(0.32, 0.37, 0.42, 1.0)
	card.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if CollectionManager.is_discovered(item.item_id):
		label.text = item.display_name
	else:
		label.text = "？？？"
		label.modulate = LOCKED_MODULATE
	card.add_child(label)
	return card


func _refresh_achievements() -> void:
	for child in achievement_list.get_children():
		child.queue_free()
	for achievement in CollectionManager.ACHIEVEMENTS:
		achievement_list.add_child(_make_achievement_row(achievement))


func _make_achievement_row(achievement: Dictionary) -> Control:
	var unlocked: bool = CollectionManager.is_unlocked(achievement["id"])
	var row := Label.new()
	var mark := "★" if unlocked else "☆"
	row.text = "%s %s — %s" % [mark, String(achievement["title"]), String(achievement["desc"])]
	row.modulate = UNLOCK_COLOR if unlocked else LOCKED_MODULATE
	return row


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_border_width_all(1)
	style.border_color = Color(0.5, 0.56, 0.62, 1.0)
	panel.add_theme_stylebox_override("panel", style)
