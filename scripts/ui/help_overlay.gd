extends Control

@onready var panel: PanelContainer = $Panel
@onready var hint_label: Label = $CornerHint

var _intro_seen := false


func _ready() -> void:
	panel.visible = false
	hint_label.text = "H 操作说明"
	call_deferred("_show_first_day_hint")


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_help"):
		_toggle_panel()
		get_viewport().set_input_as_handled()
	elif panel.visible and Input.is_action_just_pressed("interact"):
		panel.visible = false
		get_viewport().set_input_as_handled()


func _show_first_day_hint() -> void:
	if _intro_seen:
		return
	_intro_seen = true
	$FirstDayHint.visible = true
	await get_tree().create_timer(7.0).timeout
	if is_instance_valid($FirstDayHint):
		$FirstDayHint.visible = false


func _toggle_panel() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		$FirstDayHint.visible = false
