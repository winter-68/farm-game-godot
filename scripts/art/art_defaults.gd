class_name ArtDefaults
extends RefCounted

## Small helper for art-ready systems: use real textures when present,
## otherwise create simple pixel-safe placeholder textures.

static func solid_texture(size: Vector2i, color: Color) -> Texture2D:
	var image := Image.create(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)
	image.fill(color)
	return ImageTexture.create_from_image(image)


static func item_placeholder_color(item_id: StringName) -> Color:
	var id := String(item_id)
	if id.begins_with("seed_"):
		return Color(0.42, 0.75, 0.28, 1.0)
	if id.begins_with("produce_"):
		return Color(0.30, 0.82, 0.38, 1.0)
	if id.begins_with("fish_"):
		return Color(0.35, 0.65, 0.95, 1.0)
	if id.begins_with("food_"):
		return Color(0.90, 0.58, 0.28, 1.0)
	if id.begins_with("bait_"):
		return Color(0.70, 0.46, 0.24, 1.0)
	if id.begins_with("rod_") or id.begins_with("tool_"):
		return Color(0.76, 0.76, 0.72, 1.0)
	return Color(0.75, 0.75, 0.75, 1.0)


static func item_texture(item: ItemData) -> Texture2D:
	if item != null and item.icon != null:
		return item.icon
	var item_id := item.item_id if item != null else &""
	return solid_texture(Vector2i(16, 16), item_placeholder_color(item_id))


static func crop_stage_texture(crop_data: CropData, stage: int) -> Texture2D:
	if crop_data != null and stage >= 0 and stage < crop_data.stage_textures.size():
		var texture: Texture2D = crop_data.stage_textures[stage]
		if texture != null:
			return texture
	var color := crop_data.placeholder_color if crop_data != null else Color(0.25, 0.85, 0.3, 1.0)
	return solid_texture(Vector2i(16, 16), color)


static func npc_texture(npc_data: Resource) -> Texture2D:
	if npc_data != null and npc_data.get("sprite_texture") != null:
		return npc_data.get("sprite_texture")
	if npc_data != null and npc_data.get("portrait") != null:
		return npc_data.get("portrait")
	var color := Color(0.45, 0.75, 0.48, 1.0)
	if npc_data != null and npc_data.get("placeholder_color") != null:
		color = npc_data.get("placeholder_color")
	return solid_texture(Vector2i(16, 24), color)


static func player_placeholder(player_art: Resource = null) -> Texture2D:
	var color := Color(0.337, 0.769, 0.451, 1.0)
	if player_art != null and player_art.get("placeholder_color") != null:
		color = player_art.get("placeholder_color")
	return solid_texture(Vector2i(16, 24), color)
