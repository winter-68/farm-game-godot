extends Control

const TYPE_INTERVAL := 0.05

@onready var panel: PanelContainer = $Panel
@onready var portrait_rect: TextureRect = $Panel/MarginContainer/HBoxContainer/Portrait
@onready var name_label: Label = $Panel/MarginContainer/HBoxContainer/TextBox/Header/NameLabel
@onready var heart_label: Label = $Panel/MarginContainer/HBoxContainer/TextBox/Header/HeartLabel
@onready var dialogue_label: Label = $Panel/MarginContainer/HBoxContainer/TextBox/DialogueLabel
@onready var type_timer: Timer = $TypeTimer

var _npc_data: Resource
var _dialogues: PackedStringArray = []
var _dialogue_index := 0
var _char_index := 0
var _current_text := ""
var _typing := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	type_timer.wait_time = TYPE_INTERVAL
	type_timer.timeout.connect(_on_type_timer_timeout)
	EventBus.dialogue_requested.connect(start_dialogue)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("dialogue_continue"):
		get_viewport().set_input_as_handled()
		_advance()


func StartDialogue(data: Resource) -> void:
	start_dialogue(data)


func start_dialogue(data: Resource) -> void:
	if data == null:
		return
	_npc_data = data
	_dialogues = data.dialogues
	if _dialogues.is_empty():
		_dialogues = PackedStringArray(["……"])
	_dialogue_index = 0
	visible = true
	EventBus.dialogue_active_changed.emit(true)
	_apply_npc_data()
	_show_line()


func _apply_npc_data() -> void:
	portrait_rect.texture = _npc_data.portrait
	name_label.text = _npc_data.npc_name
	name_label.add_theme_color_override("font_color", _npc_data.name_color)
	_refresh_heart_label()


func _show_line() -> void:
	_current_text = _dialogues[_dialogue_index]
	_char_index = 0
	_typing = true
	dialogue_label.text = ""
	type_timer.start()


func _advance() -> void:
	if _typing:
		_finish_current_line()
		return
	_dialogue_index += 1
	if _dialogue_index >= _dialogues.size():
		_close()
	else:
		_show_line()


func _finish_current_line() -> void:
	_typing = false
	type_timer.stop()
	dialogue_label.text = _current_text


func _close() -> void:
	type_timer.stop()
	FriendshipManager.add_friendship(_npc_data.npc_name, 5)
	visible = false
	_typing = false
	EventBus.dialogue_active_changed.emit(false)


func _on_type_timer_timeout() -> void:
	_char_index += 1
	dialogue_label.text = _current_text.substr(0, _char_index)
	if _char_index >= _current_text.length():
		_finish_current_line()


func _refresh_heart_label() -> void:
	var value := FriendshipManager.get_friendship(_npc_data.npc_name)
	var hearts := clampi(value / 25, 0, 4)
	heart_label.text = "♥ x %d" % hearts
