extends Control

@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var controls_card: PanelContainer = $ControlsCard
@onready var new_game_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/NewGameButton
@onready var continue_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContinueButton
@onready var controls_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ControlsButton
@onready var quit_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/QuitButton
@onready var controls_close_button: Button = $ControlsCard/MarginContainer/VBoxContainer/CloseButton


func _ready() -> void:
	_set_panel_style(panel, Color(0.055, 0.12, 0.075, 0.97), Color(0.69, 0.55, 0.25, 1.0))
	_set_panel_style(controls_card, Color(0.045, 0.10, 0.06, 0.985), Color(0.82, 0.67, 0.30, 1.0))
	continue_button.disabled = not SaveManager.has_save(0)
	new_game_button.pressed.connect(GameManager.new_game)
	continue_button.pressed.connect(GameManager.continue_game)
	controls_button.pressed.connect(_open_controls)
	controls_close_button.pressed.connect(_close_controls)
	quit_button.pressed.connect(get_tree().quit)
	new_game_button.grab_focus()


func _input(event: InputEvent) -> void:
	if controls_card.visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		_close_controls()
		get_viewport().set_input_as_handled()


func _open_controls() -> void:
	controls_card.visible = true
	controls_close_button.grab_focus()


func _close_controls() -> void:
	controls_card.visible = false
	controls_button.grab_focus()


func _set_panel_style(target: PanelContainer, background: Color, border: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_border_width_all(2)
	style.border_color = border
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.shadow_color = Color(0, 0, 0, 0.34)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	target.add_theme_stylebox_override("panel", style)
