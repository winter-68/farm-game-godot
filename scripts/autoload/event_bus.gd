extends Node

signal request_use_item(item_id: StringName, cell: Vector2i)
signal request_harvest(cell: Vector2i)

signal time_changed(day: int, hour: int, minute: int)
signal day_passed(new_day: int)
signal season_changed(season_name: String)
signal weather_changed(weather_id: StringName)

signal money_changed(new_amount: int)
signal inventory_changed()
signal selected_slot_changed(index: int)

signal tile_tilled(cell: Vector2i)
signal tile_watered(cell: Vector2i)
signal crop_planted(cell: Vector2i, crop_id: StringName)
signal crop_grew(cell: Vector2i, stage: int)
signal crop_harvested(cell: Vector2i, produce_id: StringName, amount: int)

signal collection_discovered(produce_id: StringName)
signal achievement_unlocked(achievement_id: StringName, title: String)
signal save_load_started()

signal game_saved(slot: int)
signal game_loaded(slot: int)
signal request_open_shop()
