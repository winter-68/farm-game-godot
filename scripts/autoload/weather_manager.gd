extends Node

const WEATHER_SUNNY := &"sunny"
const WEATHER_CLOUDY := &"cloudy"
const WEATHER_RAIN := &"rain"
const WEATHER_SNOW := &"snow"

const WEATHER_NAMES := {
	&"sunny": "晴",
	&"cloudy": "多云",
	&"rain": "雨",
	&"snow": "雪",
}

# 春/夏/秋分别使用不同的晴、多云、雨概率；冬季固定为雪。
const SEASON_WEIGHTS := {
	0: [0.55, 0.25, 0.20],
	1: [0.40, 0.25, 0.35],
	2: [0.50, 0.30, 0.20],
}

var current_weather: StringName = WEATHER_SUNNY
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	EventBus.day_passed.connect(_on_day_passed)


## Resets the weather for a new game using the starting season's probabilities.
func new_game() -> void:
	_set_weather_for_current_day()


## Returns the stable weather ID used by gameplay systems.
func get_weather_id() -> StringName:
	return current_weather


## Returns the display name used by the HUD.
func get_weather_name() -> String:
	return String(WEATHER_NAMES.get(current_weather, "晴"))


func is_rain() -> bool:
	return current_weather == WEATHER_RAIN


func is_snow() -> bool:
	return current_weather == WEATHER_SNOW


## Returns weather state in save-friendly form.
func to_save_dict() -> Dictionary:
	return {"current_weather": String(current_weather)}


## Restores weather without rolling a new random result.
func load_from_dict(d: Dictionary) -> void:
	var saved_id := StringName(d.get("current_weather", d.get("weather", "")))
	if TimeManager.season == 3:
		current_weather = WEATHER_SNOW
	elif WEATHER_NAMES.has(saved_id):
		current_weather = saved_id
	else:
		current_weather = _roll_weather()
	EventBus.weather_changed.emit(current_weather)


func _on_day_passed(_new_day: int) -> void:
	_set_weather_for_current_day()
	if is_rain():
		# FarmManager consumes yesterday's water in the same day_passed signal.
		# Defer today's rain until that growth/reset pass has completed.
		call_deferred("_apply_rain")


func _set_weather_for_current_day() -> void:
	current_weather = _roll_weather()
	EventBus.weather_changed.emit(current_weather)


func _apply_rain() -> void:
	if is_rain():
		FarmManager.water_all_tilled()


func _roll_weather() -> StringName:
	if TimeManager.season == 3:
		return WEATHER_SNOW
	var weights: Array = SEASON_WEIGHTS.get(TimeManager.season, SEASON_WEIGHTS[0])
	var roll := _rng.randf()
	if roll < float(weights[0]):
		return WEATHER_SUNNY
	if roll < float(weights[0]) + float(weights[1]):
		return WEATHER_CLOUDY
	return WEATHER_RAIN
