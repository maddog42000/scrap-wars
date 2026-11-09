extends Control

func _draw() -> void:
	var build: Dictionary = GameState.selected_build()
	var chassis: Dictionary = GameState.CHASSIS[build.chassis]
	var body_color := Color("5c696b")
	var rect := Rect2(Vector2(147, 111), Vector2(286, 90))
	var parts: Dictionary = build.parts
	if build.chassis == "CH-02":
		rect = Rect2(Vector2(156, 126), Vector2(270, 62))
	elif build.chassis == "CH-03":
		rect = Rect2(Vector2(137, 99), Vector2(306, 112))
	var chassis_key := "machines/chassis/" + str(build.chassis).to_lower()
	if not ArtAssets.draw_texture(self, chassis_key, rect):
		draw_rect(rect, body_color, true)
		draw_rect(rect, Color("172124"), false, 5)
		draw_rect(Rect2(rect.position + Vector2(62, 12), Vector2(112, 22)), Color("a2844e"), true)
		for rivet in [Vector2(160, 123),Vector2(205,123),Vector2(365,123),Vector2(408,123)]:
			draw_circle(rivet, 4, Color("e5bd6c"))
	# Wheel bays remain physical attachment point previews; selected movement type is labeled at sockets.
	var wheel_points := [Vector2(192, 212),Vector2(387, 212)]
	var drive_sockets := ["drive_left", "drive_right"]
	for i in 2:
		var pos: Vector2 = wheel_points[i]
		var drive_part: Dictionary = parts.get(drive_sockets[i], {})
		var drive_id := str(drive_part.get("id", "MV-01")).to_lower()
		if not ArtAssets.draw_texture(self, "components/locomotion/" + drive_id, Rect2(pos - Vector2(34, 34), Vector2(68, 68))):
			draw_circle(pos, 34, Color("273337"))
			draw_arc(pos, 34, 0, TAU, 32, Color("d3a654"), 4)
			for j in 6:
				var a := float(j) * TAU / 6.0
				draw_line(pos + Vector2(cos(a),sin(a))*11, pos + Vector2(cos(a),sin(a))*28, Color("85908c"), 4)
	# Equipped component labels rendered as original mechanical forms.
	if parts.has("front_weapon"):
		var wid := str(parts.front_weapon.id)
		if not ArtAssets.draw_texture(self, "components/weapons/" + wid.to_lower(), Rect2(Vector2(412, 119), Vector2(74, 74))):
			var c := Color("d9a44e") if wid == "WP-01" else Color("b7c1bb")
			draw_circle(Vector2(449, 159), 27, c)
			if wid == "WP-02":
				for i in 8:
					var a := float(i) * TAU / 8.0
					draw_line(Vector2(449,159)+Vector2(cos(a),sin(a))*20,Vector2(449,159)+Vector2(cos(a),sin(a))*31,Color("f0cf77"),3)
			elif wid == "WP-03":
				draw_line(Vector2(414,132),Vector2(448,111),Color("d99d48"),8)
				draw_rect(Rect2(Vector2(443,101),Vector2(32,19)),Color("677478"),true)
			elif wid == "WP-04":
				draw_rect(Rect2(Vector2(416,143),Vector2(52,29)),Color("859a9b"),true)
			else:
				for i in 4:
					var a2 := float(i)*TAU/4.0
					draw_line(Vector2(449,159),Vector2(449,159)+Vector2(cos(a2),sin(a2))*26,Color("fff0a8"),3)
	if parts.has("rear_utility"):
		var utility_id := str(parts.rear_utility.id)
		if not ArtAssets.draw_texture(self, "components/utility/" + utility_id.to_lower(), Rect2(Vector2(110, 138), Vector2(50, 50))):
			draw_rect(Rect2(Vector2(118,143),Vector2(35,40)),Color("6f7772"),true)
			for i in 3: draw_line(Vector2(123,150+i*11),Vector2(148,150+i*11),Color("d7ae5f"),2)
	if parts.has("upper_armor") or parts.has("side_armor_left") or parts.has("side_armor_right") or parts.has("lower_armor"):
		draw_line(Vector2(rect.position.x+12,rect.position.y-5),Vector2(rect.position.x+rect.size.x-8,rect.position.y-5),Color("bc7941"),9)
	for armor_socket in ["upper_armor", "lower_armor", "side_armor_left", "side_armor_right"]:
		if parts.has(armor_socket):
			var armor_id := str(parts[armor_socket].id)
			var armor_point: Vector2 = _socket_position_for_preview(build.chassis, armor_socket)
			ArtAssets.draw_texture(self, "components/armor/" + armor_id.to_lower(), Rect2(armor_point - Vector2(24, 12), Vector2(48, 24)))
	# Socket diagram markers.
	for entry in _socket_points(build.chassis):
		var socket_id: String = entry[0]
		var p: Vector2 = entry[1]
		var installed := parts.has(socket_id)
		draw_circle(p, 14, Color("dfb55e") if installed else Color("588f86"))
		draw_arc(p, 14, 0, TAU, 20, Color("fff0ba"), 2)
		draw_string(ThemeDB.fallback_font, p+Vector2(-8,5), "+", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("172124"))
		if installed:
			var rotation_degrees := float(parts[socket_id].get("rotation", 0))
			var direction := Vector2.RIGHT.rotated(deg_to_rad(rotation_degrees))
			draw_line(p-direction*8.0,p+direction*8.0,Color("142023"),2.5)

func _socket_position_for_preview(chassis_id: String, socket_id: String) -> Vector2:
	for entry in _socket_points(chassis_id):
		if str(entry[0]) == socket_id:
			return entry[1]
	return Vector2.ZERO

func _socket_points(chassis_id: String) -> Array:
	var points := [["front_weapon",Vector2(458,133)],["rear_utility",Vector2(122,190)],["drive_left",Vector2(192,212)],["drive_right",Vector2(387,212)]]
	if chassis_id == "CH-01":
		points.append_array([["upper_armor",Vector2(278,103)],["lower_armor",Vector2(278,209)]])
	elif chassis_id == "CH-02":
		points.append_array([["side_armor_left",Vector2(124,166)],["side_armor_right",Vector2(455,166)]])
	else:
		points.append_array([["upper_armor",Vector2(278,94)],["side_armor_left",Vector2(120,159)],["side_armor_right",Vector2(460,159)]])
	return points
