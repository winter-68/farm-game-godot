extends Node

@export var seconds_per_game_minute: float = 0.5

var day: int = 1
var hour: int = 6
var minute: int = 0

var _elapsed_seconds: float = 0.0


func _ready() -> void:
	EventBus.time_changed.emit(day, hour, minute)


func _process(delta: float) -> void:
	if seconds_per_game_minute <= 0.0:
		return
	_elapsed_seconds += delta
	while _elapsed_seconds >= seconds_per_game_minute:
		_elapsed_seconds -= seconds_per_game_minute
		_advance_one_minute()


## Resets the clock for a new game.
func new_game() -> void:
	day = 1
	hour = 6
	minute = 0
	_elapsed_seconds = 0.0
	EventBus.time_changed.emit(day, hour, minute)


## Advances to the next day and resets the clock to 06:00.
func advance_to_next_day() -> void:
	day += 1
	hour = 6
	minute = 0
	_elapsed_seconds = 0.0
	EventBus.day_passed.emit(day)
	EventBus.time_changed.emit(day, hour, minute)


## Returns the current time state in save-friendly form.
func to_save_dict() -> Dictionary:
	return {
		"day": day,
		"hour": hour,
		"minute": minute,
	}


## Restores the time state and notifies listeners once.
func load_from_dict(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	hour = int(d.get("hour", 6))
	minute = int(d.get("minute", 0))
	_elapsed_seconds = 0.0
	EventBus.time_changed.emit(day, hour, minute)


func _advance_one_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour = (hour + 1) % 24
	EventBus.time_changed.emit(day, hour, minute)
