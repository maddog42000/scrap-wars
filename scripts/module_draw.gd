extends RigidBody2D

func _ready() -> void:
	_refresh_external_animation()

func _asset_key() -> String:
	var configured := str(get_meta("asset_key", ""))
	if not configured.is_empty():
		return configured
	var kind := str(get_meta("module_kind", "armor"))
	if kind == "counterweight":
		return "components/utility/ut-02"
	if kind == "shock":
		return "components/utility/ut-01"
	return "components/armor/ar-01"

func set_asset_key(asset_key: String) -> void:
	set_meta("asset_key", asset_key)
	_refresh_external_animation()
	queue_redraw()

func _refresh_external_animation() -> void:
	var kind := str(get_meta("module_kind", "armor"))
	var target_size := Vector2(36.0, 18.0) if kind == "shock" else (Vector2(36.0, 36.0) if kind == "counterweight" else Vector2(46.0, 22.0))
	if name.begins_with("Armor_front"):
		target_size = Vector2(30.0, 64.0)
	ArtAssets.mount_animation_visual(self, _asset_key(), target_size)

func _draw() -> void:
	var kind := str(get_meta("module_kind", "armor"))
	if bool(get_meta("external_animation_enabled", false)):
		return
	var size := Vector2(36.0, 18.0) if kind == "shock" else (Vector2(36.0, 36.0) if kind == "counterweight" else Vector2(46.0, 22.0))
	if name.begins_with("Armor_front"):
		size = Vector2(30.0, 64.0)
	if ArtAssets.draw_texture(self, _asset_key(), Rect2(-size * 0.5, size)):
		return
	if kind == "counterweight":
		draw_circle(Vector2.ZERO, 18, Color("4a5c60"))
		draw_arc(Vector2.ZERO, 18, 0.0, TAU, 32, Color("d7ad5d"), 4)
		draw_circle(Vector2.ZERO, 6, Color("c5a96d"))
		return
	if kind == "shock":
		draw_line(Vector2(-22, 0), Vector2(22, 0), Color("d79e4e"), 5)
		for i in 4:
			var x := -14.0 + float(i) * 9.0
			draw_line(Vector2(x, -8), Vector2(x + 5, 8), Color("c9d0c5"), 3)
		draw_circle(Vector2(-22, 0), 4, Color("65777a"))
		draw_circle(Vector2(22, 0), 4, Color("65777a"))
		return
	var fill := Color("41494a") if bool(get_meta("wrecked", false)) else Color("a26a3e")
	var trim := Color("666c69") if bool(get_meta("wrecked", false)) else Color("e0ae5c")
	draw_rect(Rect2(-size * 0.5, size), fill, true)
	draw_rect(Rect2(-size * 0.5, size), trim, false, 3)
	draw_line(Vector2(-size.x * 0.3, -size.y * 0.25), Vector2(size.x * 0.3, -size.y * 0.25), Color("e8c982"), 2)
	draw_circle(Vector2(-size.x * 0.32, 0), 2.5, Color("272e2d"))
	draw_circle(Vector2(size.x * 0.32, 0), 2.5, Color("272e2d"))
