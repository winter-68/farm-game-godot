extends Node2D

const TREE_CANOPY := Color(0.12, 0.34, 0.13, 1.0)
const TREE_CANOPY_LIGHT := Color(0.22, 0.48, 0.2, 1.0)
const TREE_TRUNK := Color(0.28, 0.16, 0.08, 1.0)
const ROCK := Color(0.45, 0.48, 0.4, 1.0)
const FLOWER_WHITE := Color(0.95, 0.95, 0.82, 1.0)
const FLOWER_RED := Color(0.95, 0.34, 0.24, 1.0)
const FENCE := Color(0.48, 0.28, 0.11, 1.0)
const PATH_LIGHT := Color(0.68, 0.51, 0.28, 0.42)


func _ready() -> void:
	z_index = -5
	queue_redraw()


func _draw() -> void:
	_draw_grass_texture()
	_draw_path_texture()
	_draw_tree_groups()
	_draw_rocks_and_flowers()
	_draw_fences()
	_draw_pond_details()


func _draw_grass_texture() -> void:
	for y in range(24, 800, 32):
		for x in range(24, 1260, 36):
			if (x + y) % 5 == 0:
				draw_circle(Vector2(x, y), 1.5, Color(0.8, 0.86, 0.32, 0.5))
			elif (x + y) % 7 == 0:
				draw_line(Vector2(x - 2, y + 2), Vector2(x + 2, y - 2), Color(0.22, 0.46, 0.16, 0.45), 1.0)


func _draw_path_texture() -> void:
	for y in range(110, 750, 22):
		draw_circle(Vector2(640 + sin(y * 0.08) * 12.0, y), 7.0, PATH_LIGHT)
	for x in range(190, 1090, 22):
		draw_circle(Vector2(x, 416 + sin(x * 0.06) * 5.0), 6.0, PATH_LIGHT)


func _draw_tree_groups() -> void:
	var points := [
		Vector2(40, 64), Vector2(110, 56), Vector2(172, 36), Vector2(292, 58),
		Vector2(384, 76), Vector2(456, 54), Vector2(910, 48), Vector2(980, 60),
		Vector2(1240, 72), Vector2(1176, 336), Vector2(1232, 394), Vector2(1108, 612),
		Vector2(1036, 656), Vector2(880, 700), Vector2(328, 680), Vector2(72, 744),
		Vector2(88, 560), Vector2(372, 360), Vector2(436, 312), Vector2(1140, 520)
	]
	for point in points:
		_draw_tree(point)


func _draw_tree(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(-4, 10), Vector2(8, 18)), TREE_TRUNK)
	draw_circle(pos + Vector2(-10, 0), 18, TREE_CANOPY)
	draw_circle(pos + Vector2(10, 0), 18, TREE_CANOPY)
	draw_circle(pos + Vector2(0, -12), 20, TREE_CANOPY_LIGHT)
	draw_circle(pos + Vector2(0, 5), 19, TREE_CANOPY)


func _draw_rocks_and_flowers() -> void:
	var rocks := [Vector2(492, 254), Vector2(748, 328), Vector2(774, 320), Vector2(1120, 288), Vector2(1010, 568), Vector2(220, 566), Vector2(101, 690)]
	for point in rocks:
		draw_circle(point, 7.0, ROCK)
		draw_circle(point + Vector2(5, 2), 5.0, Color(0.35, 0.38, 0.32, 1.0))
	var flowers := [Vector2(156, 350), Vector2(236, 354), Vector2(503, 332), Vector2(800, 356), Vector2(910, 560), Vector2(1060, 535), Vector2(1180, 455), Vector2(385, 530), Vector2(220, 704), Vector2(540, 92)]
	for i in flowers.size():
		_draw_flower(flowers[i], FLOWER_WHITE if i % 2 == 0 else FLOWER_RED)


func _draw_flower(pos: Vector2, color: Color) -> void:
	draw_circle(pos + Vector2(-2, 0), 2.0, color)
	draw_circle(pos + Vector2(2, 0), 2.0, color)
	draw_circle(pos + Vector2(0, -2), 2.0, color)
	draw_circle(pos + Vector2(0, 2), 2.0, color)
	draw_circle(pos, 1.2, Color(1.0, 0.84, 0.22, 1.0))


func _draw_fences() -> void:
	_draw_fence_line(Vector2(430, 474), Vector2(850, 474))
	_draw_fence_line(Vector2(430, 748), Vector2(850, 748))
	_draw_fence_line(Vector2(430, 474), Vector2(430, 748))
	_draw_fence_line(Vector2(850, 474), Vector2(850, 748))
	_draw_fence_line(Vector2(780, 296), Vector2(944, 296))
	_draw_fence_line(Vector2(540, 344), Vector2(612, 344))
	_draw_fence_line(Vector2(92, 390), Vector2(164, 390))


func _draw_fence_line(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, FENCE, 3.0)
	var length := a.distance_to(b)
	var steps := int(length / 28.0)
	for i in range(steps + 1):
		var p := a.lerp(b, float(i) / maxf(float(steps), 1.0))
		draw_rect(Rect2(p + Vector2(-3, -10), Vector2(6, 20)), FENCE)


func _draw_pond_details() -> void:
	for point in [Vector2(140, 662), Vector2(205, 715), Vector2(1100, 132), Vector2(1166, 190)]:
		draw_ellipse(point, 12.0, 4.0, Color(0.35, 0.67, 0.45, 0.85))
	for point in [Vector2(260, 730), Vector2(1018, 240)]:
		draw_rect(Rect2(point, Vector2(28, 10)), Color(0.36, 0.2, 0.09, 1.0))
