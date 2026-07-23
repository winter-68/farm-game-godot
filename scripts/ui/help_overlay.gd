extends Control

@onready var panel: PanelContainer = $Panel
@onready var hint_label: Label = $CornerHint
@onready var first_day_hint: PanelContainer = $FirstDayHint
@onready var first_day_label: Label = $FirstDayHint/Label

var _guidance_step := &"start"
var _step_before_water_empty := &"start"
var _guidance_token := 0
var _panel_was_open := false


func _ready() -> void:
	panel.visible = false
	hint_label.text = "H 操作说明"
	EventBus.tile_tilled.connect(_on_tile_tilled)
	EventBus.crop_planted.connect(_on_crop_planted)
	EventBus.tile_watered.connect(_on_tile_watered)
	EventBus.crop_inspected.connect(_on_crop_inspected)
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.watering_can_changed.connect(_on_watering_can_changed)
	call_deferred("_show_guidance", "先用 WASD 走到田地旁，选中锄头，按 J 翻地。")


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_help"):
		_toggle_panel()
		get_viewport().set_input_as_handled()
	elif panel.visible and Input.is_action_just_pressed("interact"):
		_close_panel()
		get_viewport().set_input_as_handled()


func _show_guidance(text: String, auto_hide_seconds: float = 0.0) -> void:
	if panel.visible:
		return
	_guidance_token += 1
	var token := _guidance_token
	first_day_label.text = text
	first_day_hint.visible = true
	if auto_hide_seconds <= 0.0:
		return
	await get_tree().create_timer(auto_hide_seconds).timeout
	if token == _guidance_token and is_instance_valid(first_day_hint):
		first_day_hint.visible = false


func _toggle_panel() -> void:
	if panel.visible:
		_close_panel()
	else:
		_open_panel()


func _open_panel() -> void:
	_panel_was_open = true
	panel.visible = true
	first_day_hint.visible = false


func _close_panel() -> void:
	panel.visible = false
	if _panel_was_open:
		_panel_was_open = false
		_refresh_current_guidance()


func _refresh_current_guidance() -> void:
	match _guidance_step:
		&"start":
			_show_guidance("先用 WASD 走到田地旁，选中锄头，按 J 翻地。")
		&"tilled":
			_show_guidance("地翻好了：选一个种子，面对翻好的地按 J 播种。")
		&"planted":
			_show_guidance("种下了：选水壶，面对作物按 J 浇水。")
		&"watered":
			_show_guidance("今天照顾好了：按 Enter 睡觉，第二天继续浇水。")
		&"harvestable":
			_show_guidance("作物成熟了：面对它按空格收获。")
		&"done":
			_show_guidance("收获完成：按 B 去商店卖作物，或继续种下一轮。", 5.0)
		&"water_empty":
			_show_guidance("水壶空了：走到池塘边按 E 打水。")


func _advance_guidance(step: StringName, text: String, auto_hide_seconds: float = 0.0) -> void:
	if _guidance_step == step:
		return
	_guidance_step = step
	_show_guidance(text, auto_hide_seconds)


func _on_tile_tilled(_cell: Vector2i) -> void:
	if _guidance_step == &"start":
		_advance_guidance(&"tilled", "地翻好了：选一个种子，面对翻好的地按 J 播种。")


func _on_crop_planted(_cell: Vector2i, _crop_id: StringName) -> void:
	if _guidance_step in [&"start", &"tilled"]:
		_advance_guidance(&"planted", "种下了：选水壶，面对作物按 J 浇水。")


func _on_tile_watered(_cell: Vector2i) -> void:
	if _guidance_step in [&"start", &"tilled", &"planted", &"water_empty"]:
		_advance_guidance(&"watered", "今天照顾好了：按 Enter 睡觉，第二天继续浇水。")


func _on_crop_inspected(_crop_id: StringName, _stage: int, _mature_stage: int, _watered_days: int, _days_per_stage: int, harvestable: bool) -> void:
	if harvestable and _guidance_step != &"done":
		_advance_guidance(&"harvestable", "作物成熟了：面对它按空格收获。")


func _on_crop_harvested(_cell: Vector2i, _produce_id: StringName, _amount: int) -> void:
	_advance_guidance(&"done", "收获完成：按 B 去商店卖作物，或继续种下一轮。", 5.0)


func _on_watering_can_changed(current: int, _maximum: int) -> void:
	if current == 0 and _guidance_step != &"done":
		_step_before_water_empty = _guidance_step
		_advance_guidance(&"water_empty", "水壶空了：走到池塘边按 E 打水。")
	elif current > 0 and _guidance_step == &"water_empty":
		_guidance_step = _step_before_water_empty
		_refresh_current_guidance()
