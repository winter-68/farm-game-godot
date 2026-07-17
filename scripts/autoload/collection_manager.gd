extends Node

# Achievement order is also the display order used by the collection panel.
const ACHIEVEMENTS := [
	{"id": &"first_harvest", "title": "初次收获", "desc": "收获第一份作物"},
	{"id": &"harvest_50", "title": "小有收成", "desc": "累计收获 50 份作物"},
	{"id": &"harvest_200", "title": "丰收能手", "desc": "累计收获 200 份作物"},
	{"id": &"collector", "title": "作物学家", "desc": "图鉴集齐所有作物"},
	{"id": &"all_seasons", "title": "四季轮回", "desc": "经历春夏秋冬四个季节"},
	{"id": &"rich", "title": "小富农", "desc": "金币达到 1000"},
	{"id": &"first_season", "title": "扎根", "desc": "坚持到第 28 天"},
]

var discovered: Dictionary = {}
var fish_discovered: Dictionary = {}
var recipe_discovered: Dictionary = {}
var total_harvested: int = 0
var max_money: int = 0
var seasons_seen: Dictionary = {}
var unlocked: Dictionary = {}

var _loading: bool = false


func _ready() -> void:
	EventBus.crop_harvested.connect(_on_crop_harvested)
	EventBus.fish_caught.connect(_on_fish_caught)
	EventBus.recipe_discovered.connect(_on_recipe_discovered)
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.season_changed.connect(_on_season_changed)
	EventBus.day_passed.connect(_on_day_passed)
	EventBus.save_load_started.connect(_on_save_load_started)
	EventBus.game_loaded.connect(_on_game_loaded)


## Resets all collection and achievement progress for a new game.
func new_game() -> void:
	discovered.clear()
	fish_discovered.clear()
	recipe_discovered.clear()
	total_harvested = 0
	max_money = 0
	seasons_seen.clear()
	unlocked.clear()
	seasons_seen[TimeManager.season] = true


func is_discovered(produce_id: StringName) -> bool:
	return discovered.has(String(produce_id))


func is_fish_discovered(fish_item_id: StringName) -> bool:
	return fish_discovered.has(String(fish_item_id))


func is_recipe_discovered(recipe_id: StringName) -> bool:
	return recipe_discovered.has(String(recipe_id))


func is_unlocked(achievement_id: StringName) -> bool:
	return unlocked.has(String(achievement_id))


## Returns the number of produce definitions in the full collection.
func total_produce_count() -> int:
	var n := 0
	for item: ItemData in ItemDatabase.get_all_items():
		if item != null and item.type == ItemData.Type.PRODUCE:
			n += 1
	return n


func discovered_count() -> int:
	return discovered.size()


func fish_discovered_count() -> int:
	return fish_discovered.size()


func to_save_dict() -> Dictionary:
	return {
		"discovered": discovered.keys(),
		"fish_discovered": fish_discovered.keys(),
		"recipe_discovered": recipe_discovered.keys(),
		"total_harvested": total_harvested,
		"max_money": max_money,
		"seasons_seen": seasons_seen.keys(),
		"unlocked": unlocked.keys(),
	}


## Restores progress without replaying unlock notifications.
func load_from_dict(d: Dictionary) -> void:
	discovered.clear()
	for k in d.get("discovered", []):
		discovered[String(k)] = true
	fish_discovered.clear()
	for k in d.get("fish_discovered", []):
		fish_discovered[String(k)] = true
	recipe_discovered.clear()
	for k in d.get("recipe_discovered", []):
		recipe_discovered[String(k)] = true
	total_harvested = int(d.get("total_harvested", 0))
	max_money = int(d.get("max_money", 0))
	seasons_seen.clear()
	for s in d.get("seasons_seen", []):
		seasons_seen[int(s)] = true
	unlocked.clear()
	for u in d.get("unlocked", []):
		unlocked[String(u)] = true


func _on_save_load_started() -> void:
	_loading = true


func _on_game_loaded(_slot: int) -> void:
	_loading = false


func _on_crop_harvested(_cell: Vector2i, produce_id: StringName, amount: int) -> void:
	if _loading:
		return
	total_harvested += maxi(amount, 0)
	if not discovered.has(String(produce_id)):
		discovered[String(produce_id)] = true
		EventBus.collection_discovered.emit(produce_id)
	_evaluate()


func _on_fish_caught(fish_data: Resource) -> void:
	if _loading:
		return
	var item_id := ItemDatabase.get_fish_item_id(fish_data)
	if item_id == &"" or fish_discovered.has(String(item_id)):
		return
	fish_discovered[String(item_id)] = true
	EventBus.fish_discovered.emit(item_id)


func _on_recipe_discovered(recipe_id: StringName) -> void:
	if _loading or recipe_discovered.has(String(recipe_id)):
		return
	recipe_discovered[String(recipe_id)] = true


func _on_money_changed(new_amount: int) -> void:
	if _loading:
		return
	if new_amount > max_money:
		max_money = new_amount
	_evaluate()


func _on_season_changed(_season_name: String) -> void:
	if _loading:
		return
	seasons_seen[TimeManager.season] = true
	_evaluate()


func _on_day_passed(_new_day: int) -> void:
	if _loading:
		return
	_evaluate()


func _evaluate() -> void:
	if total_harvested >= 1:
		_unlock(&"first_harvest")
	if total_harvested >= 50:
		_unlock(&"harvest_50")
	if total_harvested >= 200:
		_unlock(&"harvest_200")
	var produce_total := total_produce_count()
	if produce_total > 0 and discovered_count() >= produce_total:
		_unlock(&"collector")
	if seasons_seen.size() >= 4:
		_unlock(&"all_seasons")
	if max_money >= 1000:
		_unlock(&"rich")
	if TimeManager.day >= 28:
		_unlock(&"first_season")


func _unlock(id: StringName) -> void:
	if unlocked.has(String(id)):
		return
	unlocked[String(id)] = true
	var title := _title_of(id)
	print("[Collection] 解锁成就：%s" % title)
	EventBus.achievement_unlocked.emit(id, title)


func _title_of(id: StringName) -> String:
	for achievement in ACHIEVEMENTS:
		if achievement["id"] == id:
			return String(achievement["title"])
	return String(id)
