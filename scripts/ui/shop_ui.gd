extends Control

const ArtDefaults := preload("res://scripts/art/art_defaults.gd")

const ITEM_SHORT_NAMES := {
	&"seed_greenbean": "绿豆种子",
	&"produce_greenbean": "绿豆",
	&"seed_potato": "土豆种子",
	&"produce_potato": "土豆",
	&"seed_tomato": "番茄种子",
	&"produce_tomato": "番茄",
	&"seed_strawberry": "草莓种子",
	&"produce_strawberry": "草莓",
	&"fish_crucian": "鲫鱼",
	&"fish_carp": "鲤鱼",
	&"fish_bass": "鲈鱼",
	&"fish_goldfish": "金鱼",
	&"fish_pufferfish": "河豚",
	&"bait_basic": "基础鱼饵",
	&"bait_quality": "优质鱼饵",
	&"bait_legend": "传说鱼饵",
	&"rod_iron": "铁竿",
	&"rod_gold": "金竿",
	&"food_baked_potato": "烤土豆",
	&"food_tomato_soup": "番茄汤",
	&"food_strawberry_dessert": "草莓甜点",
}

@onready var panel: PanelContainer = $Panel
@onready var sell_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/SellList
@onready var buy_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/BuyList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	_set_static_texts()
	_set_panel_style()
	EventBus.request_open_shop.connect(_open)
	EventBus.inventory_changed.connect(_on_state_changed)
	EventBus.money_changed.connect(_on_state_changed)
	EventBus.ui_panel_changed.connect(_on_ui_panel_changed)
	close_button.pressed.connect(_close)


func _input(event: InputEvent) -> void:
	# Dev shortcut: the world ShopEntrance is the normal player-facing entry.
	if event.is_action_pressed("toggle_shop") and not event.is_echo():
		_set_open(not visible)
		get_viewport().set_input_as_handled()


func _open() -> void:
	_set_open(true)


func _close() -> void:
	_set_open(false)


func _set_open(open: bool) -> void:
	visible = open
	if open:
		_refresh()
		UIStateManager.open_panel(&"shop")
	else:
		UIStateManager.close_panel(&"shop")


func _on_ui_panel_changed(active_panel: StringName) -> void:
	if visible and active_panel != &"shop":
		visible = false


func _on_state_changed(_value = null) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	_refresh_sell()
	_refresh_buy()


func _refresh_sell() -> void:
	for child in sell_list.get_children():
		child.queue_free()

	var sellable_counts := _get_sellable_counts()
	if sellable_counts.is_empty():
		var empty_label := Label.new()
		empty_label.text = "没有可出售物品"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sell_list.add_child(empty_label)
		return

	for item_id in sellable_counts.keys():
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item == null:
			continue
		var quantity := int(sellable_counts[item_id])
		sell_list.add_child(_make_sell_row(item, quantity, _get_sell_price(item)))


func _refresh_buy() -> void:
	for child in buy_list.get_children():
		child.queue_free()

	for item in ItemDatabase.get_all_items():
		if item == null or item.buy_price <= 0:
			continue
		if item.type == ItemData.Type.ROD:
			if item.item_id == FishingManager.current_rod_id:
				continue
			buy_list.add_child(_make_rod_buy_row(item))
			continue
		if item.type == ItemData.Type.SEED:
			var crop: CropData = ItemDatabase.get_crop(item.linked_crop_id)
			if crop != null:
				var allowed := crop.allowed_seasons
				if not allowed.is_empty() and not allowed.has(TimeManager.get_season_name()):
					continue
		buy_list.add_child(_make_buy_row(item))


func _get_sellable_counts() -> Dictionary:
	var counts := {}
	for slot: Dictionary in InventoryManager.slots:
		var item_id := StringName(slot.get("item_id", &""))
		if item_id == &"":
			continue
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item == null or _get_sell_price(item) <= 0:
			continue
		counts[item_id] = int(counts.get(item_id, 0)) + int(slot.get("quantity", 0))
	return counts


func _make_sell_row(item: ItemData, quantity: int, sell_price: int) -> HBoxContainer:
	var row := _make_item_row_base(item)
	var label := row.get_node("Label") as Label
	label.text = "%s ×%d  单价%d" % [_get_item_name(item), quantity, sell_price]
	label.custom_minimum_size = Vector2(112, 0)

	var sell_one_button := Button.new()
	sell_one_button.text = "卖1"
	sell_one_button.custom_minimum_size = Vector2(42, 22)
	sell_one_button.pressed.connect(_sell_one.bind(item.item_id, sell_price))
	row.add_child(sell_one_button)

	var sell_all_button := Button.new()
	sell_all_button.text = "全卖"
	sell_all_button.custom_minimum_size = Vector2(48, 22)
	sell_all_button.pressed.connect(_sell_all.bind(item.item_id, sell_price))
	row.add_child(sell_all_button)

	return row


func _make_buy_row(item: ItemData) -> HBoxContainer:
	var row := _make_item_row_base(item)
	var label := row.get_node("Label") as Label
	label.text = "%s  单价%d" % [_get_item_name(item), item.buy_price]
	label.custom_minimum_size = Vector2(154, 0)

	var buy_one_button := Button.new()
	buy_one_button.text = "买1"
	buy_one_button.custom_minimum_size = Vector2(42, 22)
	buy_one_button.pressed.connect(_buy_one.bind(item.item_id, item.buy_price))
	row.add_child(buy_one_button)

	return row


func _make_rod_buy_row(item: ItemData) -> HBoxContainer:
	var row := _make_item_row_base(item)
	var rod := ItemDatabase.get_rod(item.item_id)
	var required_level := int(rod.required_level) if rod != null else 0
	var can_buy := FishingManager.get_level() >= required_level

	var label := row.get_node("Label") as Label
	label.text = "%s  单价%d" % [_get_item_name(item), item.buy_price]
	if not can_buy:
		label.text += "  需要 Lv.%d" % required_level
		label.modulate = Color(0.55, 0.55, 0.55, 1.0)
	label.custom_minimum_size = Vector2(154, 0)

	var buy_one_button := Button.new()
	buy_one_button.text = "装备" if can_buy else "未解锁"
	buy_one_button.disabled = not can_buy
	buy_one_button.custom_minimum_size = Vector2(52, 22)
	buy_one_button.pressed.connect(_buy_rod.bind(item.item_id, item.buy_price))
	row.add_child(buy_one_button)

	return row


func _make_item_row_base(item: ItemData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	row.add_theme_constant_override("separation", 4)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(16, 16)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture = ArtDefaults.item_texture(item)
	row.add_child(icon)

	var label := Label.new()
	label.name = "Label"
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return row


func _sell_one(item_id: StringName, sell_price: int) -> void:
	if InventoryManager.remove_item(item_id, 1):
		InventoryManager.add_money(sell_price)


func _sell_all(item_id: StringName, sell_price: int) -> void:
	var quantity := InventoryManager.count_item(item_id)
	if quantity <= 0:
		return
	if InventoryManager.remove_item(item_id, quantity):
		InventoryManager.add_money(sell_price * quantity)


func _buy_one(item_id: StringName, buy_price: int) -> void:
	if not InventoryManager.try_spend(buy_price):
		return
	var leftover := InventoryManager.add_item(item_id, 1)
	if leftover > 0:
		InventoryManager.add_money(buy_price * leftover)


func _buy_rod(rod_id: StringName, buy_price: int) -> void:
	var rod := ItemDatabase.get_rod(rod_id)
	if rod == null:
		return
	if FishingManager.get_level() < int(rod.required_level):
		return
	if not InventoryManager.try_spend(buy_price):
		return
	FishingManager.set_rod(rod_id)
	_refresh()


func _get_item_name(item: ItemData) -> String:
	return ITEM_SHORT_NAMES.get(item.item_id, item.display_name)


func _get_sell_price(item: ItemData) -> int:
	if item.type == ItemData.Type.FISH:
		var fish := ItemDatabase.get_fish(item.item_id)
		if fish != null:
			return int(fish.sell_price)
	if item.type == ItemData.Type.BAIT:
		var bait: Resource = ItemDatabase.get_bait(item.item_id)
		if bait != null:
			return int(bait.sell_price)
	return item.sell_price


func _set_static_texts() -> void:
	$Panel/MarginContainer/VBoxContainer/Title.text = "商店"
	$Panel/MarginContainer/VBoxContainer/SellTitle.text = "出售"
	$Panel/MarginContainer/VBoxContainer/BuyTitle.text = "购买"
	close_button.text = "关闭"


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.10, 0.07, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.42, 0.68, 0.42, 1.0)
	panel.add_theme_stylebox_override("panel", style)
