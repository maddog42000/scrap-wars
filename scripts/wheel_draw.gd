extends RigidBody2D

func _ready() -> void:
	_refresh_external_animation()

func set_asset_key(asset_key: String) -> void:
	set_meta("asset_key", asset_key)
	_refresh_external_animation()
	queue_redraw()

func _refresh_external_animation() -> void:
	var key := str(get_meta("asset_key", ""))
	if key.is_empty():
		key = "components/locomotion/mv-01"
	ArtAssets.mount_animation_visual(self, key, Vector2(52.0, 52.0))

func _draw() -> void:
	var asset_key := str(get_meta("asset_key", "components/locomotion/mv-01"))
	if bool(get_meta("external_animation_enabled", false)):
		return
	var wheel_size := 52.0 if name.begins_with("PoweredWheel") else 26.0
	if ArtAssets.draw_texture(self, asset_key, Rect2(Vector2(-wheel_size * 0.5, -wheel_size * 0.5), Vector2.ONE * wheel_size)):
		return
	var col: Color = get_meta("draw_color", Color("303c41"))
	var radius := wheel_size * 0.5
	draw_circle(Vector2.ZERO, radius, col)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color("c4a35b"), 3.0)
	if name.begins_with("PoweredWheel"):
		draw_circle(Vector2.ZERO, 8.0, Color("a2aaa4"))
		for i in 8:
			var a := TAU * float(i) / 8.0
			draw_line(Vector2(cos(a), sin(a)) * 10.0, Vector2(cos(a), sin(a)) * 22.0, Color("88938e"), 3.0)
	else:
		draw_circle(Vector2.ZERO, 4.0, Color("f3c65e"))
