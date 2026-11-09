extends RigidBody2D

func _ready() -> void:
	_refresh_external_animation()

func set_asset_key(asset_key: String) -> void:
	set_meta("asset_key", asset_key)
	_refresh_external_animation()
	queue_redraw()

func _refresh_external_animation() -> void:
	var key := str(get_meta("asset_key", "components/weapons/wp-03"))
	ArtAssets.mount_animation_visual(self, key, Vector2(60.0, 42.0))

func _draw() -> void:
	var asset_key := str(get_meta("asset_key", "components/weapons/wp-03"))
	if bool(get_meta("external_animation_enabled", false)):
		return
	if ArtAssets.draw_texture(self, asset_key, Rect2(Vector2(-30.0, -21.0), Vector2(60.0, 42.0))):
		return
	var direction := float(get_meta("dir", 1.0))
	var pivot := Vector2(-direction * 30.0, 0)
	draw_line(pivot, Vector2.ZERO, Color("d7973f"), 10.0)
	draw_line(pivot + Vector2(0, 3), Vector2.ZERO + Vector2(0, 3), Color("754d2b"), 2.0)
	draw_rect(Rect2(Vector2(-19, -12), Vector2(38, 24)), Color("616e70"), true)
	draw_rect(Rect2(Vector2(-19, -12), Vector2(38, 24)), Color("d8b36a"), false, 3.0)
	draw_line(Vector2(-10, -6), Vector2(10, -6), Color("aeb6b0"), 2.0)
	draw_circle(Vector2(-13, 0), 2.0, Color("1c2628"))
	draw_circle(Vector2(13, 0), 2.0, Color("1c2628"))
