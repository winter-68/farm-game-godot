extends Area2D

enum Action { SHOP, SLEEP, COOKING, ENTER_HOME, ENTER_KITCHEN, EXIT_WORLD }

@export var action: Action = Action.SHOP
@export var prompt_text: String = "按 E 互动"
@export var return_position: Vector2 = Vector2.ZERO

@onready var prompt_label: Label = $PromptLabel

var _player_inside := false


func _ready() -> void:
	prompt_label.text = prompt_text
	prompt_label.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or not event.is_action_pressed("dialogue_continue"):
		return
	match action:
		Action.SHOP:
			EventBus.request_open_shop.emit()
		Action.SLEEP:
			TimeManager.advance_to_next_day()
		Action.COOKING:
			EventBus.request_open_cooking.emit()
		Action.ENTER_HOME:
			_call_world("enter_interior", [&"home"])
		Action.ENTER_KITCHEN:
			_call_world("enter_interior", [&"kitchen"])
		Action.EXIT_WORLD:
			_call_world("exit_interior", [return_position])
	get_viewport().set_input_as_handled()


func _call_world(method: StringName, args: Array) -> void:
	var world := get_tree().get_first_node_in_group("world_root")
	if world == null or not world.has_method(method):
		return
	world.callv(method, args)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		prompt_label.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		prompt_label.visible = false
