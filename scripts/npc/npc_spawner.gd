extends Node

const NPC_SCENE := preload("res://scenes/npc/npc.tscn")

@export var npc_datas: Array[Resource] = []


func _ready() -> void:
	for data in npc_datas:
		if data == null:
			continue
		var npc := NPC_SCENE.instantiate()
		npc.set_npc_data(data)
		npc.global_position = data.spawn_position
		add_child(npc)
