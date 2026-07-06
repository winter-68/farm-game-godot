extends Node2D

@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var farm_layer: TileMapLayer = $FarmLayer
@onready var tile_highlight: Sprite2D = $TileHighlight
@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	FarmManager.register_layers(ground_layer, farm_layer)
	$CropsRoot.register_ground(ground_layer)
	player.ground_layer = ground_layer
	player.update_target_cell()
	_update_tile_highlight()
	GameManager.register_player(player)
	if GameManager.consume_pending_load():
		call_deferred("_deferred_load")


func _process(_delta: float) -> void:
	_update_tile_highlight()


func _update_tile_highlight() -> void:
	var cell_center := ground_layer.map_to_local(player.target_cell)
	tile_highlight.global_position = ground_layer.to_global(cell_center)


func _deferred_load() -> void:
	SaveManager.load_game(0)
