extends Area2D

@onready var prompt_label: Label = $PromptLabel

var _player_inside := false


func _ready() -> void:
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or not event.is_action_pressed("dialogue_continue"):
		return
	EventBus.fishing_started.emit(self)
	get_viewport().set_input_as_handled()


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		prompt_label.visible = false
