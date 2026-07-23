class_name NPCData
extends Resource

@export var npc_name: String = ""
@export var sprite_texture: Texture2D
@export var portrait: Texture2D
@export_group("Movement Frames")
@export var stand_down: Texture2D
@export var stand_up: Texture2D
@export var stand_left: Texture2D
@export var stand_right: Texture2D
@export var walk_down: Array[Texture2D] = []
@export var walk_up: Array[Texture2D] = []
@export var walk_left: Array[Texture2D] = []
@export var walk_right: Array[Texture2D] = []
@export var frame_time: float = 0.22
@export_group("")
@export var placeholder_color: Color = Color(0.45, 0.75, 0.48, 1.0)
@export var dialogues: PackedStringArray = []
@export var name_color: Color = Color.WHITE
@export var spawn_position: Vector2 = Vector2.ZERO
@export var move_area: Rect2 = Rect2()
@export var max_friendship: int = 100
@export var heart_stages: PackedStringArray = []
