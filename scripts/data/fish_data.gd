class_name FishData
extends Resource

@export var fish_name: String = ""
@export var icon: Texture2D
@export var sell_price: int = 0
@export_range(0.0, 1.0, 0.01) var rarity: float = 0.0
@export var available_seasons: Array[String] = []
@export var available_time: String = "全天"
@export var min_level: int = 0
@export var xp_reward: int = 0
