extends Node2D

@export_enum("home", "kitchen") var room_kind := "home"
@export var use_generated_art := false


func _ready() -> void:
	if use_generated_art:
		queue_redraw()


func _draw() -> void:
	if not use_generated_art:
		return
	if room_kind == "kitchen":
		_draw_kitchen()
	else:
		_draw_home()


func _draw_room_base(floor_color: Color, wall_color: Color) -> void:
	draw_rect(Rect2(Vector2(96, 72), Vector2(448, 80)), wall_color)
	draw_rect(Rect2(Vector2(96, 152), Vector2(448, 248)), floor_color)
	draw_rect(Rect2(Vector2(96, 72), Vector2(448, 328)), Color(0.16, 0.08, 0.03, 1.0), false, 5.0)
	for x in range(112, 528, 32):
		draw_line(Vector2(x, 152), Vector2(x, 398), Color(0.28, 0.14, 0.06, 0.22), 1.0)
	for y in range(172, 398, 28):
		draw_line(Vector2(100, y), Vector2(540, y), Color(0.28, 0.14, 0.06, 0.2), 1.0)
	draw_rect(Rect2(Vector2(292, 384), Vector2(56, 40)), Color(0.72, 0.5, 0.24, 1.0))
	draw_rect(Rect2(Vector2(300, 392), Vector2(40, 24)), Color(0.85, 0.68, 0.36, 1.0))


func _draw_home() -> void:
	_draw_room_base(Color(0.52, 0.28, 0.12, 1.0), Color(0.7, 0.49, 0.28, 1.0))
	_draw_bed(Vector2(138, 205))
	_draw_bookshelf(Vector2(250, 105))
	_draw_table(Vector2(330, 245))
	_draw_cabinet(Vector2(444, 112))
	_draw_plant(Vector2(482, 314))
	_draw_rug(Rect2(Vector2(132, 260), Vector2(140, 84)), Color(0.42, 0.55, 0.27, 1.0))


func _draw_kitchen() -> void:
	_draw_room_base(Color(0.42, 0.39, 0.34, 1.0), Color(0.64, 0.43, 0.24, 1.0))
	_draw_stove(Vector2(134, 128))
	_draw_counter(Vector2(246, 132))
	_draw_sink(Vector2(344, 136))
	_draw_fridge(Vector2(452, 112))
	_draw_table(Vector2(310, 270))
	_draw_crates(Vector2(470, 326))
	_draw_rug(Rect2(Vector2(190, 328), Vector2(104, 40)), Color(0.23, 0.39, 0.2, 1.0))


func _draw_bed(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(70, 108)), Color(0.31, 0.17, 0.08, 1.0))
	draw_rect(Rect2(pos + Vector2(8, 10), Vector2(54, 84)), Color(0.66, 0.78, 0.48, 1.0))
	draw_rect(Rect2(pos + Vector2(10, 12), Vector2(50, 24)), Color(0.92, 0.82, 0.62, 1.0))


func _draw_bookshelf(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(88, 84)), Color(0.34, 0.18, 0.08, 1.0))
	for y in [12, 38, 64]:
		draw_line(pos + Vector2(6, y), pos + Vector2(82, y), Color(0.16, 0.08, 0.03, 1.0), 2.0)
	for x in range(12, 76, 12):
		draw_rect(Rect2(pos + Vector2(x, 16), Vector2(7, 20)), Color(0.35 + fmod(x, 3) * 0.15, 0.38, 0.18, 1.0))


func _draw_table(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(88, 50)), Color(0.45, 0.24, 0.1, 1.0))
	draw_circle(pos + Vector2(44, 25), 10.0, Color(0.95, 0.82, 0.44, 1.0))


func _draw_cabinet(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(70, 78)), Color(0.32, 0.19, 0.11, 1.0))
	draw_rect(Rect2(pos + Vector2(8, 10), Vector2(54, 26)), Color(0.55, 0.82, 0.85, 1.0))


func _draw_plant(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-8, 10), Vector2(16, 14)), Color(0.45, 0.23, 0.08, 1.0))
	draw_circle(pos, 12.0, Color(0.2, 0.48, 0.18, 1.0))


func _draw_rug(rect: Rect2, color: Color) -> void:
	draw_rect(rect, Color(0.25, 0.11, 0.07, 1.0))
	draw_rect(rect.grow(-6), color)


func _draw_stove(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(84, 84)), Color(0.16, 0.15, 0.14, 1.0))
	draw_rect(Rect2(pos + Vector2(10, 46), Vector2(64, 26)), Color(0.95, 0.42, 0.18, 0.8))
	draw_rect(Rect2(pos + Vector2(32, -44), Vector2(20, 48)), Color(0.2, 0.18, 0.16, 1.0))


func _draw_counter(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(80, 54)), Color(0.42, 0.24, 0.12, 1.0))
	draw_rect(Rect2(pos + Vector2(8, 8), Vector2(64, 16)), Color(0.7, 0.62, 0.48, 1.0))


func _draw_sink(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(90, 56)), Color(0.44, 0.27, 0.14, 1.0))
	draw_rect(Rect2(pos + Vector2(18, 12), Vector2(54, 26)), Color(0.55, 0.68, 0.68, 1.0))


func _draw_fridge(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(56, 116)), Color(0.5, 0.52, 0.48, 1.0))
	draw_line(pos + Vector2(0, 54), pos + Vector2(56, 54), Color(0.22, 0.24, 0.22, 1.0), 2.0)


func _draw_crates(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(54, 34)), Color(0.45, 0.24, 0.1, 1.0))
	draw_rect(Rect2(pos + Vector2(62, -18), Vector2(34, 52)), Color(0.42, 0.21, 0.09, 1.0))
