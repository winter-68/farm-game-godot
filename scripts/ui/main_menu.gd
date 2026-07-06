extends Control

@onready var new_game_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/NewGameButton
@onready var continue_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/ContinueButton
@onready var quit_button: Button = $CenterContainer/Panel/MarginContainer/VBoxContainer/QuitButton


func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save(0)
	new_game_button.pressed.connect(GameManager.new_game)
	continue_button.pressed.connect(GameManager.continue_game)
	quit_button.pressed.connect(get_tree().quit)
