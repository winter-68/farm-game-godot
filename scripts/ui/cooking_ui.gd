extends Control

const ArtDefaults := preload("res://scripts/art/art_defaults.gd")

const RECIPE_NAMES := {
	&"recipe_baked_potato": "烤土豆",
	&"recipe_tomato_soup": "番茄汤",
	&"recipe_strawberry_dessert": "草莓甜点",
}
const ITEM_NAMES := {
	&"produce_potato": "土豆",
	&"produce_tomato": "番茄",
	&"produce_strawberry": "草莓",
	&"food_baked_potato": "烤土豆",
	&"food_tomato_soup": "番茄汤",
	&"food_strawberry_dessert": "草莓甜点",
}

@onready var panel: PanelContainer = $Panel
@onready var status_label: Label = $Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var recipe_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/RecipeList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton

var _cooking := false


func _ready() -> void:
	visible = false
	_set_static_texts()
	_set_panel_style()
	EventBus.request_open_cooking.connect(_open)
	EventBus.inventory_changed.connect(_on_inventory_changed)
	close_button.pressed.connect(_close)
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_inventory"):
		_close()
		get_viewport().set_input_as_handled()


func _open() -> void:
	visible = true
	status_label.text = "选择一道菜开始制作"
	_refresh()


func _close() -> void:
	visible = false


func _refresh() -> void:
	for child in recipe_list.get_children():
		child.queue_free()
	for recipe in RecipeDatabase.get_all_recipes():
		recipe_list.add_child(_make_recipe_row(recipe))


func _make_recipe_row(recipe: Resource) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 28)
	row.add_theme_constant_override("separation", 4)

	var result_item: ItemData = ItemDatabase.get_item(recipe.result_item_id)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = ArtDefaults.item_texture(result_item)
	row.add_child(icon)

	var label := Label.new()
	label.text = "%s  %s" % [_get_recipe_name(recipe), _format_ingredients(recipe)]
	label.custom_minimum_size = Vector2(136, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var button := Button.new()
	button.text = "制作"
	button.disabled = _cooking or not _has_ingredients(recipe)
	button.custom_minimum_size = Vector2(74, 22)
	button.pressed.connect(_cook.bind(recipe))
	row.add_child(button)

	return row


func _cook(recipe: Resource) -> void:
	if _cooking or not _has_ingredients(recipe):
		return
	_cooking = true
	_refresh()
	for index in range(recipe.ingredient_ids.size()):
		InventoryManager.remove_item(recipe.ingredient_ids[index], int(recipe.ingredient_amounts[index]))
	status_label.text = "制作中：%s..." % _get_recipe_name(recipe)
	await get_tree().create_timer(float(recipe.cooking_time)).timeout
	var leftover := InventoryManager.add_item(recipe.result_item_id, int(recipe.result_amount))
	var result_name := _get_item_name(recipe.result_item_id)
	if leftover == 0:
		status_label.text = "制作完成：%s" % result_name
		EventBus.recipe_discovered.emit(recipe.recipe_id)
	else:
		_refund_ingredients(recipe)
		status_label.text = "背包已满，制作失败"
	_cooking = false
	_refresh()


func _has_ingredients(recipe: Resource) -> bool:
	for index in range(recipe.ingredient_ids.size()):
		var item_id: StringName = recipe.ingredient_ids[index]
		var amount := int(recipe.ingredient_amounts[index])
		if not InventoryManager.has_item(item_id, amount):
			return false
	return true


func _format_ingredients(recipe: Resource) -> String:
	var parts: Array[String] = []
	for index in range(recipe.ingredient_ids.size()):
		var item_id: StringName = recipe.ingredient_ids[index]
		var amount := int(recipe.ingredient_amounts[index])
		var have := InventoryManager.count_item(item_id)
		parts.append("%s %d/%d" % [_get_item_name(item_id), have, amount])
	return "，".join(parts)


func _refund_ingredients(recipe: Resource) -> void:
	for index in range(recipe.ingredient_ids.size()):
		InventoryManager.add_item(recipe.ingredient_ids[index], int(recipe.ingredient_amounts[index]))


func _get_recipe_name(recipe: Resource) -> String:
	return RECIPE_NAMES.get(recipe.recipe_id, String(recipe.recipe_name))


func _get_item_name(item_id: StringName) -> String:
	if ITEM_NAMES.has(item_id):
		return ITEM_NAMES[item_id]
	var item: ItemData = ItemDatabase.get_item(item_id)
	return item.display_name if item != null else String(item_id)


func _on_inventory_changed() -> void:
	if visible:
		_refresh()


func _set_static_texts() -> void:
	$Panel/MarginContainer/VBoxContainer/Title.text = "厨房"
	close_button.text = "关闭"


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.08, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.58, 0.36, 0.58, 1.0)
	panel.add_theme_stylebox_override("panel", style)
