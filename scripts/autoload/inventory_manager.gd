extends Node

const SLOT_COUNT := 30

var money: int = 0
var slots: Array = []
var selected_index: int = 0


func _ready() -> void:
	_setup_new_game()


## Adds items to existing stacks, then empty slots, and returns the remainder.
func add_item(item_id: StringName, amount: int) -> int:
	if amount <= 0:
		return 0
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null:
		push_warning("[InventoryManager] Unknown item id: %s" % item_id)
		return amount

	var remaining := amount
	var max_stack := maxi(item.max_stack, 1) if item.stackable else 1
	if item.stackable:
		for i in range(slots.size()):
			var slot: Dictionary = slots[i]
			if slot["item_id"] != item_id or slot["quantity"] >= max_stack:
				continue
			var added := mini(remaining, max_stack - int(slot["quantity"]))
			slot["quantity"] = int(slot["quantity"]) + added
			slots[i] = slot
			remaining -= added
			if remaining == 0:
				break

	if remaining > 0:
		for i in range(slots.size()):
			if slots[i]["item_id"] != &"":
				continue
			var added := mini(remaining, max_stack)
			slots[i] = {"item_id": item_id, "quantity": added}
			remaining -= added
			if remaining == 0:
				break

	if remaining != amount:
		EventBus.inventory_changed.emit()
	return remaining


## Removes the requested amount atomically when enough items are available.
func remove_item(item_id: StringName, amount: int) -> bool:
	if amount <= 0:
		return true
	if not has_item(item_id, amount):
		return false

	var remaining := amount
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if slot["item_id"] != item_id:
			continue
		var removed := mini(remaining, int(slot["quantity"]))
		var new_quantity := int(slot["quantity"]) - removed
		slots[i] = _empty_slot() if new_quantity == 0 else {
			"item_id": item_id,
			"quantity": new_quantity,
		}
		remaining -= removed
		if remaining == 0:
			break

	EventBus.inventory_changed.emit()
	return true


## Returns the total quantity of an item across all slots.
func count_item(item_id: StringName) -> int:
	var total := 0
	for slot: Dictionary in slots:
		if slot["item_id"] == item_id:
			total += int(slot["quantity"])
	return total


## Returns whether the inventory contains at least the requested amount.
func has_item(item_id: StringName, amount: int) -> bool:
	return amount <= 0 or count_item(item_id) >= amount


## Adds money and broadcasts the new balance.
func add_money(amount: int) -> void:
	money += amount
	EventBus.money_changed.emit(money)


## Spends money when affordable and reports whether the transaction succeeded.
func try_spend(amount: int) -> bool:
	if amount < 0:
		push_warning("[InventoryManager] Cannot spend a negative amount")
		return false
	if money < amount:
		return false
	money -= amount
	EventBus.money_changed.emit(money)
	return true


## Returns a copy of the currently selected slot.
func get_selected() -> Dictionary:
	if slots.is_empty():
		return _empty_slot()
	return (slots[selected_index] as Dictionary).duplicate()


## Returns the item ID in the currently selected slot.
func get_selected_item_id() -> StringName:
	return StringName(get_selected().get("item_id", &""))


## Selects a clamped slot index and broadcasts changes.
func set_selected(index: int) -> void:
	var clamped_index := clampi(index, 0, SLOT_COUNT - 1)
	if clamped_index == selected_index:
		return
	selected_index = clamped_index
	EventBus.selected_slot_changed.emit(selected_index)


## Returns inventory and money state in save-friendly form.
func to_save_dict() -> Dictionary:
	var saved_slots: Array = []
	for slot: Dictionary in slots:
		saved_slots.append({
			"item_id": String(slot["item_id"]),
			"quantity": int(slot["quantity"]),
		})
	return {
		"money": money,
		"selected_index": selected_index,
		"slots": saved_slots,
	}


## Restores inventory and money state, then broadcasts the complete state.
func load_from_dict(d: Dictionary) -> void:
	money = int(d.get("money", 0))
	selected_index = clampi(int(d.get("selected_index", 0)), 0, SLOT_COUNT - 1)
	slots.clear()
	var saved_slots: Array = d.get("slots", []) as Array
	for i in range(SLOT_COUNT):
		if i >= saved_slots.size() or not saved_slots[i] is Dictionary:
			slots.append(_empty_slot())
			continue
		var saved_slot: Dictionary = saved_slots[i]
		var item_id := StringName(saved_slot.get("item_id", ""))
		var quantity := maxi(int(saved_slot.get("quantity", 0)), 0)
		slots.append(
			_empty_slot()
			if item_id == &"" or quantity == 0
			else {"item_id": item_id, "quantity": quantity}
		)
	_emit_state_changed()


## Resets inventory, money, and selected slot for a new game.
func new_game() -> void:
	_setup_new_game()


func _setup_new_game() -> void:
	money = 200
	selected_index = 0
	slots.clear()
	for i in range(SLOT_COUNT):
		slots.append(_empty_slot())
	slots[0] = {"item_id": &"tool_hoe", "quantity": 1}
	slots[1] = {"item_id": &"tool_wateringcan", "quantity": 1}
	call_deferred("_emit_state_changed")


func _emit_state_changed() -> void:
	EventBus.money_changed.emit(money)
	EventBus.inventory_changed.emit()
	EventBus.selected_slot_changed.emit(selected_index)


func _empty_slot() -> Dictionary:
	return {"item_id": &"", "quantity": 0}
