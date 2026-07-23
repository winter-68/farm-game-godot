extends Node

var active_panel: StringName = &""


func has_active_panel() -> bool:
	return active_panel != &""


func open_panel(panel_id: StringName) -> void:
	if active_panel == panel_id:
		return
	active_panel = panel_id
	EventBus.ui_panel_changed.emit(active_panel)


func close_panel(panel_id: StringName) -> void:
	if active_panel != panel_id:
		return
	active_panel = &""
	EventBus.ui_panel_changed.emit(active_panel)
