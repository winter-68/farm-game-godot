extends Control

var _money: int = 0

@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel


func _ready() -> void:
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.money_changed.connect(_on_money_changed)
	_on_time_changed(TimeManager.day, TimeManager.hour, TimeManager.minute)
	_on_money_changed(InventoryManager.money)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_sleep"):
		TimeManager.advance_to_next_day()


func _on_time_changed(day: int, hour: int, minute: int) -> void:
	time_label.text = "第 %d 天  %02d:%02d" % [day, hour, minute]


func _on_day_passed(new_day: int) -> void:
	_on_time_changed(new_day, TimeManager.hour, TimeManager.minute)


func _on_money_changed(new_amount: int) -> void:
	_money = new_amount
	money_label.text = "金币: %d" % _money
