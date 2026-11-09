extends RigidBody2D

func _ready() -> void:
	_refresh_external_animation()

func set_asset_key(asset_key: String, target_size := Vector2(28.0, 28.0)) -> void:
	set_meta("asset_key", asset_key)
	set_meta("asset_target_size", target_size)
	_refresh_external_animation()
	queue_redraw()

func _refresh_external_animation() -> void:
	var kind := str(get_meta("kind", "axle"))
	var default_key := "components/locomotion/crank-axle" if kind == "axle" else "components/locomotion/crank-leg"
	var key := str(get_meta("asset_key", default_key))
	var target_size: Vector2 = get_meta("asset_target_size", Vector2(28.0, 28.0) if kind == "axle" else Vector2(24.0, 60.0))
	ArtAssets.mount_animation_visual(self, key, target_size)

func _draw() -> void:
	var kind: String = str(get_meta("kind", "axle"))
	var default_key := "components/locomotion/crank-axle" if kind == "axle" else "components/locomotion/crank-leg"
	var asset_key := str(get_meta("asset_key", default_key))
	if bool(get_meta("external_animation_enabled", false)):
		return
	var image_size: Vector2 = get_meta("asset_target_size", Vector2(28.0, 28.0) if kind == "axle" else Vector2(24.0, 60.0))
	if ArtAssets.draw_texture(self, asset_key, Rect2(-image_size * 0.5, image_size)):
		return
	if kind == "axle":
		draw_circle(Vector2.ZERO, 13.0, Color("d59234"))
		draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 28, Color("f1d08b"), 3.0)
		draw_circle(Vector2.ZERO, 4.0, Color("20282a"))
		draw_line(Vector2.ZERO, Vector2(12.0, 0.0), Color("ffe19b"), 4.0)
	else:
		# Original fallback art for the linked rigid leg and its contact foot.
		draw_line(Vector2(0, -13), Vector2(0, 13), Color("d29a3d"), 7.0)
		draw_circle(Vector2(0, -13), 4.0, Color("f0c266"))
		draw_rect(Rect2(Vector2(-12, 8), Vector2(24, 8)), Color("667478"), true)
		draw_rect(Rect2(Vector2(-12, 8), Vector2(24, 8)), Color("d9b366"), false, 2.0)
