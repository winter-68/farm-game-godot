extends Control

const FISH_RESOURCES: Array[Resource] = [
	preload("res://resources/fish/crucian.tres"),
	preload("res://resources/fish/carp.tres"),
	preload("res://resources/fish/bass.tres"),
	preload("res://resources/fish/goldfish.tres"),
	preload("res://resources/fish/pufferfish.tres"),
]
const WAIT_MIN_SECONDS := 2.0
const WAIT_MAX_SECONDS := 5.0
const RISE_SPEED := 0.5
const FALL_SPEED := 0.3
const BAR_HEIGHT := 92.0
const FISH_MIN_Y := 14.0
const FISH_MAX_Y := 106.0

@onready var fill: ColorRect = $Panel/BarBackground/Fill
@onready var fish_icon: Label = $Panel/FishIcon
@onready var status_label: Label = $Panel/StatusLabel
@onready var bite_timer: Timer = $BiteTimer
@onready var end_timer: Timer = $EndTimer

var _rng := RandomNumberGenerator.new()
var _active := false
var _waiting := false
var _progress := 0.5
var _fish_velocity := 70.0
var _bait_id: StringName = &""
var _bait_name := "无"
var _xp_multiplier := 1.0
var _rare_bonus := 0.0
var _rod_name := "初始鱼竿"
var _rod_speed_modifier := 1.0
var _rod_xp_multiplier := 1.0
var _rod_rare_bonus := 0.0


func _ready() -> void:
	_rng.randomize()
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	bite_timer.timeout.connect(_on_bite_timer_timeout)
	end_timer.timeout.connect(_hide)
	EventBus.fishing_started.connect(_on_fishing_started)


func _process(delta: float) -> void:
	if not _active:
		return

	_update_fish_icon(delta)
	var holding := Input.is_action_pressed("interact") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	_progress += (RISE_SPEED if holding else -FALL_SPEED) * delta
	_progress = clampf(_progress, 0.0, 1.0)
	_update_bar()

	if _progress >= 1.0:
		_finish_success()
	elif _progress <= 0.0:
		_finish_failure()


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("interact") or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()


func _on_fishing_started(_fishing_spot: Node) -> void:
	if visible:
		return
	visible = true
	EventBus.dialogue_active_changed.emit(true)
	_active = false
	_waiting = true
	_prepare_rod()
	_prepare_bait()
	_progress = 0.5
	status_label.text = "%s | 使用：%s\n等待咬钩..." % [_rod_name, _bait_name]
	_update_bar()
	fish_icon.position.y = FISH_MIN_Y + (FISH_MAX_Y - FISH_MIN_Y) * 0.5
	bite_timer.start(_rng.randf_range(WAIT_MIN_SECONDS, WAIT_MAX_SECONDS))


func _on_bite_timer_timeout() -> void:
	_waiting = false
	_active = true
	var level := FishingManager.get_level()
	_fish_velocity = _rng.randf_range(45.0 + level * 3.0, 80.0 + level * 5.0) * _rod_speed_modifier * (-1.0 if _rng.randi_range(0, 1) == 0 else 1.0)
	status_label.text = "%s | 使用：%s\n按住空格或鼠标左键！" % [_rod_name, _bait_name]


func _update_fish_icon(delta: float) -> void:
	fish_icon.position.y += _fish_velocity * delta
	if fish_icon.position.y <= FISH_MIN_Y:
		fish_icon.position.y = FISH_MIN_Y
		_fish_velocity = absf(_fish_velocity)
	elif fish_icon.position.y >= FISH_MAX_Y:
		fish_icon.position.y = FISH_MAX_Y
		_fish_velocity = -absf(_fish_velocity)


func _update_bar() -> void:
	fill.size.y = BAR_HEIGHT * _progress
	fill.position.y = BAR_HEIGHT - fill.size.y


func _finish_success() -> void:
	_active = false
	var fish := _pick_fish()
	EventBus.fish_caught.emit(fish)
	if _bait_id != &"":
		EventBus.bait_used.emit(_bait_id)
	FishingManager.add_xp(FishingManager.get_xp_reward(fish), &"fish", _rod_xp_multiplier * _xp_multiplier)
	status_label.text = "钓到了：%s！" % fish.fish_name
	end_timer.start(1.2)


func _finish_failure() -> void:
	_active = false
	status_label.text = "鱼跑了！"
	end_timer.start(1.2)


func _hide() -> void:
	visible = false
	_waiting = false
	_active = false
	EventBus.dialogue_active_changed.emit(false)


func _pick_fish() -> Resource:
	var candidates := _get_available_fish()
	var total_weight := 0.0
	for fish in candidates:
		total_weight += _weight_for_fish(fish)

	var roll := _rng.randf_range(0.0, total_weight)
	for fish in candidates:
		roll -= _weight_for_fish(fish)
		if roll <= 0.0:
			return fish
	return candidates[0]


func _weight_for_fish(fish: Resource) -> float:
	var rarity := float(fish.rarity)
	var bonus := (_rare_bonus + _rod_rare_bonus) if rarity >= 0.4 else 0.0
	return maxf(0.05, 1.0 - rarity + bonus)


func _get_available_fish() -> Array[Resource]:
	var result: Array[Resource] = []
	var level := FishingManager.get_level()
	for fish in FISH_RESOURCES:
		if int(fish.min_level) <= level:
			result.append(fish)
	if result.is_empty():
		result.append(FISH_RESOURCES[0])
	return result


func _prepare_bait() -> void:
	_bait_id = &""
	_bait_name = "无"
	_xp_multiplier = 1.0
	_rare_bonus = 0.0
	var selected := InventoryManager.get_selected()
	var item_id := StringName(selected.get("item_id", &""))
	if item_id == &"":
		return
	var item: ItemData = ItemDatabase.get_item(item_id)
	if item == null or item.type != ItemData.Type.BAIT:
		return
	var bait: Resource = ItemDatabase.get_bait(item_id)
	if bait == null:
		return
	if not InventoryManager.remove_item(item_id, 1):
		return
	_bait_id = item_id
	_bait_name = bait.display_name
	_xp_multiplier = bait.xp_multiplier
	_rare_bonus = bait.rare_bonus


func _prepare_rod() -> void:
	var rod := FishingManager.get_current_rod()
	if rod == null:
		_rod_name = "初始鱼竿"
		_rod_speed_modifier = 1.0
		_rod_xp_multiplier = 1.0
		_rod_rare_bonus = 0.0
		return
	_rod_name = rod.display_name
	_rod_speed_modifier = rod.speed_modifier
	_rod_xp_multiplier = rod.xp_multiplier
	_rod_rare_bonus = rod.rare_bonus
