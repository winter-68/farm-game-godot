extends Control

var _money: int = 0

@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var season_notice: Label = $SeasonNotice
var weather_label: Label


func _ready() -> void:
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.money_changed.connect(_on_money_changed)
	weather_label = Label.new()
	weather_label.name = "WeatherLabel"
	$MarginContainer/VBoxContainer.add_child(weather_label)
	_on_time_changed(TimeManager.day, TimeManager.hour, TimeManager.minute)
	_on_weather_changed(WeatherManager.current_weather)
	_on_money_changed(InventoryManager.money)


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_sleep"):
		TimeManager.advance_to_next_day()


func _on_time_changed(day: int, hour: int, minute: int) -> void:
	time_label.text = "%s 第 %d 天  %02d:%02d" % [
		TimeManager.get_season_name(),
		TimeManager.get_day_in_season(),
		hour,
		minute,
	]


func _on_day_passed(new_day: int) -> void:
	_on_time_changed(new_day, TimeManager.hour, TimeManager.minute)


func _on_season_changed(season_name: String) -> void:
	_on_time_changed(TimeManager.day, TimeManager.hour, TimeManager.minute)
	season_notice.text = "进入%s季" % season_name
	season_notice.visible = true
	await get_tree().create_timer(3.0).timeout
	season_notice.visible = false


func _on_weather_changed(_weather_id: StringName) -> void:
	if weather_label == null:
		return
	weather_label.text = "天气: %s" % WeatherManager.get_weather_name()


func _on_money_changed(new_amount: int) -> void:
	_money = new_amount
	money_label.text = "金币: %d" % _money
