extends Control

@onready var panel: PanelContainer = $CenterContainer/Panel
@onready var resume_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ResumeButton
@onready var fullscreen_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/FullscreenButton
@onready var main_menu_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/MainMenuButton
@onready var quit_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_set_panel_style()
	resume_button.pressed.connect(_close)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	main_menu_button.pressed.connect(_return_to_main_menu)
	quit_button.pressed.connect(get_tree().quit)
	_refresh_fullscreen_text()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()


func _open() -> void:
	visible = true
	get_tree().paused = true
	UIStateManager.open_panel(&"pause")
	_refresh_fullscreen_text()
	resume_button.grab_focus()


func _close() -> void:
	visible = false
	get_tree().paused = false
	UIStateManager.close_panel(&"pause")


func _toggle_fullscreen() -> void:
	var window := get_window()
	if window.mode == Window.MODE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN
	_refresh_fullscreen_text()


func _return_to_main_menu() -> void:
	visible = false
	get_tree().paused = false
	UIStateManager.close_panel(&"pause")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _refresh_fullscreen_text() -> void:
	fullscreen_button.text = "退出全屏" if get_window().mode == Window.MODE_FULLSCREEN else "进入全屏"


func _set_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.10, 0.07, 0.96)
	style.set_border_width_all(1)
	style.border_color = Color(0.42, 0.68, 0.42, 1.0)
	panel.add_theme_stylebox_override("panel", style)
