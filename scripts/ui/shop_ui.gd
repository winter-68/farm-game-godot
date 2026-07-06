extends Control

const ITEM_SHORT_NAMES := {
	&"seed_greenbean": "绿豆种子",
	&"produce_greenbean": "绿豆",
}

@onready var panel: PanelContainer = $Panel
@onready var sell_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/SellList
@onready var buy_list: VBoxContainer = $Panel/MarginContainer/VBoxContainer/BuyList
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	visible = false
	_set_panel_style()
	EventBus.request_open_shop.connect(_open)
	EventBus.inventory_changed.connect(_on_state_changed)
	EventBus.money_changed.connect(_on_state_changed)
	close_button.pressed.connect(_close)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_shop"):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()


func _open() -> void:
	visible = true
	_refresh()


func _close() -> void:
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
		sell_list.add_child(_make_sell_row(item, quantity))


func _refresh_buy() -> void:
	for child in buy_list.get_children():
		child.queue_free()

	for item in ItemDatabase.get_all_items():
		if item == null or item.buy_price <= 0:
			continue
		buy_list.add_child(_make_buy_row(item))


func _get_sellable_counts() -> Dictionary:
	var counts := {}
	for slot: Dictionary in InventoryManager.slots:
		var item_id := StringName(slot.get("item_id", &""))
		if item_id == &"":
			continue
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item == null or item.sell_price <= 0:
			continue
		counts[item_id] = int(counts.get(item_id, 0)) + int(slot.get("quantity", 0))
	return counts


func _make_sell_row(item: ItemData, quantity: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	row.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = "%s ×%d  单价%d" % [_get_item_name(item), quantity, item.sell_price]
	label.custom_minimum_size = Vector2(118, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var sell_one_button := Button.new()
	sell_one_button.text = "卖1"
	sell_one_button.custom_minimum_size = Vector2(42, 22)
	sell_one_button.pressed.connect(_sell_one.bind(item.item_id, item.sell_price))
	row.add_child(sell_one_button)

	var sell_all_button := Button.new()
	sell_all_button.text = "全卖"
	sell_all_button.custom_minimum_size = Vector2(48, 22)
	sell_all_button.pressed.connect(_sell_all.bind(item.item_id, item.sell_price))
	row.add_child(sell_all_button)

	return row


func _make_buy_row(item: ItemData) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 24)
	row.add_theme_constant_override("separation", 4)

	var label := Label.new()
	label.text = "%s  单价%d" % [_get_item_name(item), item.buy_price]
	label.custom_minimum_size = Vector2(168, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	var buy_one_button := Button.new()
	buy_one_button.text = "买1"
	buy_one_button.custom_minimum_size = Vector2(42, 22)
	buy_one_button.pressed.connect(_buy_one.bind(item.item_id, item.buy_price))
	row.add_child(buy_one_button)

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


func _get_item_name(item: ItemData) -> String:
	return ITEM_SHORT_NAMES.get(item.item_id, item.display_name)


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.08, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.55, 0.48, 0.32, 1.0)
	panel.add_theme_stylebox_override("panel", style)
