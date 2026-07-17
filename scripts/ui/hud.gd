extends Control

var _money: int = 0

@onready var time_label: Label = $MarginContainer/VBoxContainer/TimeLabel
@onready var money_label: Label = $MarginContainer/VBoxContainer/MoneyLabel
@onready var buff_label: Label = $MarginContainer/VBoxContainer/BuffLabel
@onready var fishing_label: Label = $FishingPanel/FishingLabel
@onready var fishing_xp_bar: ProgressBar = $FishingPanel/FishingXPBar
@onready var season_notice: Label = $SeasonNotice
@onready var stamina_label: Label = $StaminaPanel/StaminaLabel
@onready var stamina_bar: ProgressBar = $StaminaPanel/StaminaBar
@onready var crop_info: Label = $CropInfo
@onready var water_label: Label = $WaterPanel/WaterLabel
@onready var water_bar: ProgressBar = $WaterPanel/WaterBar
var weather_label: Label


func _ready() -> void:
	EventBus.time_changed.connect(_on_time_changed)
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.weather_changed.connect(_on_weather_changed)
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.fishing_xp_gained.connect(_on_fishing_changed)
	EventBus.fishing_leveled_up.connect(_on_fishing_level_up)
	EventBus.rod_changed.connect(_on_rod_changed)
	EventBus.buff_changed.connect(_refresh_buff)
	EventBus.stamina_changed.connect(_on_stamina_changed)
	EventBus.crop_inspected.connect(_on_crop_inspected)
	EventBus.watering_can_changed.connect(_on_watering_can_changed)
	weather_label = Label.new()
	weather_label.name = "WeatherLabel"
	$MarginContainer/VBoxContainer.add_child(weather_label)
	_on_time_changed(TimeManager.day, TimeManager.hour, TimeManager.minute)
	_on_weather_changed(WeatherManager.current_weather)
	_on_money_changed(InventoryManager.money)
	_refresh_fishing()
	_refresh_buff()
	_on_stamina_changed(StaminaManager.current_stamina, StaminaManager.MAX_STAMINA)
	_on_watering_can_changed(WaterManager.current_water, WaterManager.MAX_WATER)


func _process(_delta: float) -> void:
	if BuffManager.has_buff(&"move_speed"):
		_refresh_buff()


func _unhandled_input(_event: InputEvent) -> void:
	# Dev shortcut: the world SleepEntrance is the normal player-facing entry.
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


func _on_stamina_changed(current: float, maximum: float) -> void:
	stamina_bar.max_value = maximum
	stamina_bar.value = current
	stamina_label.text = "体力 %d / %d" % [roundi(current), roundi(maximum)]


func _on_crop_inspected(crop_id: StringName, stage: int, mature_stage: int, watered_days: int, days_per_stage: int, harvestable: bool) -> void:
	if crop_id == &"":
		crop_info.visible = false
		return
	var crop: CropData = ItemDatabase.get_crop(crop_id)
	if crop == null:
		crop_info.visible = false
		return
	crop_info.visible = true
	if harvestable:
		crop_info.text = "%s · 已成熟（空格收获）" % crop.display_name
		return
	crop_info.text = "%s · 成长 %d/%d · 本阶段浇水 %d/%d" % [crop.display_name, stage + 1, mature_stage + 1, watered_days, maxi(days_per_stage, 1)]


func _on_watering_can_changed(current: int, maximum: int) -> void:
	water_bar.max_value = maximum
	water_bar.value = current
	water_label.text = "水壶 %d / %d" % [current, maximum]


func _on_fishing_changed(_amount: int, _source: StringName) -> void:
	_refresh_fishing()


func _on_fishing_level_up(_new_level: int) -> void:
	_refresh_fishing()


func _on_rod_changed(_new_rod_id: StringName) -> void:
	_refresh_fishing()


func _refresh_fishing() -> void:
	var rod := FishingManager.get_current_rod()
	var rod_name: String = rod.display_name if rod != null else "初始鱼竿"
	fishing_label.text = "鱼 Lv.%d %s" % [FishingManager.get_level(), rod_name]
	fishing_xp_bar.value = FishingManager.get_xp_progress()


func _refresh_buff() -> void:
	var remaining := BuffManager.get_buff_remaining(&"move_speed")
	if remaining <= 0.0:
		buff_label.text = ""
	else:
		buff_label.text = "移速提升 %.0fs" % ceilf(remaining)
