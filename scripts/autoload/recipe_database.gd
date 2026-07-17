extends Node

const RECIPES_PATH := "res://resources/recipes"

var _recipes: Dictionary = {}


func _ready() -> void:
	_load_recipes()
	print("[RecipeDatabase] loaded %d recipes" % _recipes.size())


func get_recipe(recipe_id: StringName) -> Resource:
	return _recipes.get(recipe_id) as Resource


func get_all_recipes() -> Array:
	return _recipes.values()


func _load_recipes() -> void:
	_recipes.clear()
	var directory := DirAccess.open(RECIPES_PATH)
	if directory == null:
		push_warning("[RecipeDatabase] Could not open directory: %s" % RECIPES_PATH)
		return
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() != "tres":
			continue
		var path := RECIPES_PATH.path_join(file_name)
		var resource := ResourceLoader.load(path)
		if resource == null:
			push_warning("[RecipeDatabase] Failed to load recipe resource: %s" % path)
			continue
		if StringName(resource.get("recipe_id")) == &"":
			push_warning("[RecipeDatabase] Resource is not recipe data: %s" % path)
			continue
		_recipes[resource.recipe_id] = resource
