class_name NPCData
extends Resource

@export var npc_name: String = ""
@export var sprite_texture: Texture2D
@export var portrait: Texture2D
@export var placeholder_color: Color = Color(0.45, 0.75, 0.48, 1.0)
@export var dialogues: PackedStringArray = []
@export var name_color: Color = Color.WHITE
@export var spawn_position: Vector2 = Vector2.ZERO
@export var move_area: Rect2 = Rect2()
@export var max_friendship: int = 100
@export var heart_stages: PackedStringArray = []
