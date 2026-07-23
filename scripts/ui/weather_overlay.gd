extends Control

const RAIN_TINT := Color(0.25, 0.35, 0.55, 0.04)
const SNOW_TINT := Color(0.75, 0.80, 0.90, 0.04)
const CLOUDY_TINT := Color(0.1, 0.1, 0.12, 0.03)
const CLEAR_TINT := Color(0.0, 0.0, 0.0, 0.0)
const EMISSION_WIDTH := 680.0

@onready var tint: ColorRect = $Tint
@onready var notice: Label = $Notice

var _particles: CPUParticles2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_particles = CPUParticles2D.new()
	_particles.emitting = false
	add_child(_particles)
	notice.visible = false
	EventBus.weather_changed.connect(_on_weather_changed)
	# Pull the current state because the overlay may enter after new_game/load emitted.
	_apply_weather(WeatherManager.current_weather, false)


func _on_weather_changed(weather_id: StringName) -> void:
	_apply_weather(weather_id, true)


func _apply_weather(weather_id: StringName, announce: bool) -> void:
	match weather_id:
		WeatherManager.WEATHER_RAIN:
			tint.color = RAIN_TINT
			_setup_rain()
		WeatherManager.WEATHER_SNOW:
			tint.color = SNOW_TINT
			_setup_snow()
		WeatherManager.WEATHER_CLOUDY:
			tint.color = CLOUDY_TINT
			_particles.emitting = false
		_:
			tint.color = CLEAR_TINT
			_particles.emitting = false
	if announce:
		_show_notice(WeatherManager.get_weather_name())


func _setup_rain() -> void:
	_particles.position = Vector2(320, -8)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(EMISSION_WIDTH * 0.5, 4)
	_particles.amount = 80
	_particles.lifetime = 0.7
	_particles.direction = Vector2(0, 1)
	_particles.spread = 4.0
	_particles.gravity = Vector2(0, 300)
	_particles.initial_velocity_min = 180.0
	_particles.initial_velocity_max = 220.0
	_particles.scale_amount_min = 1.0
	_particles.scale_amount_max = 2.0
	_particles.color = Color(0.7, 0.8, 1.0, 0.45)
	_particles.emitting = true


func _setup_snow() -> void:
	_particles.position = Vector2(320, -8)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(EMISSION_WIDTH * 0.5, 4)
	_particles.amount = 50
	_particles.lifetime = 3.0
	_particles.direction = Vector2(0, 1)
	_particles.spread = 20.0
	_particles.gravity = Vector2(0, 20)
	_particles.initial_velocity_min = 15.0
	_particles.initial_velocity_max = 30.0
	_particles.scale_amount_min = 1.5
	_particles.scale_amount_max = 3.0
	_particles.color = Color(1, 1, 1, 0.55)
	_particles.emitting = true


func _show_notice(weather_name: String) -> void:
	notice.text = "今日天气：%s" % weather_name
	notice.visible = true
	await get_tree().create_timer(2.5).timeout
	notice.visible = false
