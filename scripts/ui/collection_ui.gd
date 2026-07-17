extends Control

const ArtDefaults := preload("res://scripts/art/art_defaults.gd")
const PANEL_COLOR := Color(0.06, 0.07, 0.08, 0.92)
const CARD_COLOR := Color(0.10, 0.12, 0.14, 0.95)
const LOCKED_MODULATE := Color(0.5, 0.5, 0.5, 1.0)
const UNLOCK_COLOR := Color(0.92, 0.82, 0.35, 1.0)
const ITEM_NAMES := {
	&"produce_greenbean": "绿豆",
	&"produce_potato": "土豆",
	&"produce_tomato": "番茄",
	&"produce_strawberry": "草莓",
	&"fish_crucian": "鲫鱼",
	&"fish_carp": "鲤鱼",
	&"fish_bass": "鲈鱼",
	&"fish_goldfish": "金鱼",
	&"fish_pufferfish": "河豚",
	&"food_baked_potato": "烤土豆",
	&"food_tomato_soup": "番茄汤",
	&"food_strawberry_dessert": "草莓甜点",
}
const RECIPE_NAMES := {
	&"recipe_baked_potato": "烤土豆",
	&"recipe_tomato_soup": "番茄汤",
	&"recipe_strawberry_dessert": "草莓甜点",
}
const ACHIEVEMENT_NAMES := {
	&"first_harvest": ["初次收获", "收获第一份作物"],
	&"harvest_50": ["小有收成", "累计收获 50 份作物"],
	&"harvest_200": ["丰收能手", "累计收获 200 份作物"],
	&"collector": ["作物学家", "图鉴集齐所有作物"],
	&"all_seasons": ["四季轮回", "经历春夏秋冬四个季节"],
	&"rich": ["小富农", "金币达到 1000"],
	&"first_season": ["扎根", "坚持到第 28 天"],
}

@onready var panel: PanelContainer = $Panel
@onready var crops_button: Button = $Panel/Margin/VBox/CategoryTabs/CropsButton
@onready var fish_button: Button = $Panel/Margin/VBox/CategoryTabs/FishButton
@onready var recipes_button: Button = $Panel/Margin/VBox/CategoryTabs/RecipesButton
@onready var almanac_grid: GridContainer = $Panel/Margin/VBox/AlmanacGrid
@onready var achievement_list: VBoxContainer = $Panel/Margin/VBox/AchievementList

var _category := &"crops"


func _ready() -> void:
	visible = false
	almanac_grid.columns = 4
	_set_panel_style()
	crops_button.pressed.connect(_set_category.bind(&"crops"))
	fish_button.pressed.connect(_set_category.bind(&"fish"))
	recipes_button.pressed.connect(_set_category.bind(&"recipes"))
	EventBus.collection_discovered.connect(_on_changed)
	EventBus.fish_discovered.connect(_on_changed)
	EventBus.recipe_discovered.connect(_on_recipe_discovered)
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


func _on_recipe_discovered(_recipe_id: StringName) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	_refresh_almanac()
	_refresh_achievements()


func _refresh_almanac() -> void:
	for child in almanac_grid.get_children():
		child.queue_free()
	crops_button.disabled = _category == &"crops"
	fish_button.disabled = _category == &"fish"
	recipes_button.disabled = _category == &"recipes"
	if _category == &"fish":
		_refresh_fish_almanac()
		return
	if _category == &"recipes":
		_refresh_recipe_almanac()
		return
	for item: ItemData in ItemDatabase.get_all_items():
		if item == null or item.type != ItemData.Type.PRODUCE:
			continue
		almanac_grid.add_child(_make_almanac_cell(_get_item_name(item.item_id), CollectionManager.is_discovered(item.item_id), ArtDefaults.item_texture(item)))


func _refresh_fish_almanac() -> void:
	for item: ItemData in ItemDatabase.get_all_fish_items():
		if item == null:
			continue
		almanac_grid.add_child(_make_almanac_cell(_get_item_name(item.item_id), CollectionManager.is_fish_discovered(item.item_id), ArtDefaults.item_texture(item)))


func _refresh_recipe_almanac() -> void:
	for recipe in RecipeDatabase.get_all_recipes():
		var discovered_recipe := CollectionManager.is_recipe_discovered(recipe.recipe_id)
		var label := _get_recipe_name(recipe)
		if discovered_recipe:
			label = "%s\n%s" % [label, _format_recipe_result(recipe)]
		var result_item: ItemData = ItemDatabase.get_item(recipe.result_item_id)
		almanac_grid.add_child(_make_almanac_cell(label, discovered_recipe, ArtDefaults.item_texture(result_item)))


func _make_almanac_cell(text: String, discovered_item: bool, texture: Texture2D = null) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(66, 48)
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.set_border_width_all(1)
	style.border_color = Color(0.32, 0.37, 0.42, 1.0)
	card.add_theme_stylebox_override("panel", style)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	card.add_child(box)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = texture
	icon.visible = discovered_item and texture != null
	box.add_child(icon)

	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text if discovered_item else "？？？"
	if not discovered_item:
		label.modulate = LOCKED_MODULATE
	box.add_child(label)
	return card


func _refresh_achievements() -> void:
	for child in achievement_list.get_children():
		child.queue_free()
	for achievement in CollectionManager.ACHIEVEMENTS:
		achievement_list.add_child(_make_achievement_row(achievement))


func _make_achievement_row(achievement: Dictionary) -> Control:
	var achievement_id := StringName(achievement["id"])
	var unlocked: bool = CollectionManager.is_unlocked(achievement_id)
	var text_pair: Array = ACHIEVEMENT_NAMES.get(achievement_id, [String(achievement["title"]), String(achievement["desc"])])
	var row := Label.new()
	var mark := "★" if unlocked else "☆"
	row.text = "%s %s — %s" % [mark, String(text_pair[0]), String(text_pair[1])]
	row.modulate = UNLOCK_COLOR if unlocked else LOCKED_MODULATE
	return row


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.set_border_width_all(1)
	style.border_color = Color(0.5, 0.56, 0.62, 1.0)
	panel.add_theme_stylebox_override("panel", style)


func _set_category(category: StringName) -> void:
	_category = category
	if visible:
		_refresh_almanac()


func _get_recipe_name(recipe: Resource) -> String:
	return RECIPE_NAMES.get(recipe.recipe_id, String(recipe.recipe_name))


func _format_recipe_result(recipe: Resource) -> String:
	return _get_item_name(recipe.result_item_id)


func _get_item_name(item_id: StringName) -> String:
	if ITEM_NAMES.has(item_id):
		return ITEM_NAMES[item_id]
	var item: ItemData = ItemDatabase.get_item(item_id)
	return item.display_name if item != null else String(item_id)
