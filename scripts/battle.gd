extends Node2D

const VEHICLE_SCRIPT := preload("res://scripts/vehicle.gd")
const FONT := preload("res://assets/fonts/DejaVuSans.ttf")
const VIEW := Vector2(1280, 720)
const BATTLE_SPEEDS := [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
var player: ScrapVehicle
var enemy: ScrapVehicle
var ui: CanvasLayer
var pause_overlay: Control
var pause_button: Button
var speed_readout: Label
var status_label: Label
var timer_label: Label
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var time_left := 90.0
var battle_time_limit := 90.0
var countdown := 3.0
var paused := false
var ended := false
var result_label: Label
var result_text := ""
var test_elapsed := 0.0
var physics_test := false
var rotation_test := false
var battle_controls_test := false
var auto_combat_test := false
var auto_combat_reported := false
var speed_index := 2
var initial_player_x := 0.0
var initial_enemy_x := 0.0
var max_player_advance := 0.0
var max_enemy_advance := 0.0
var max_crank_contacts := 0
var crank_rotation_start := 0.0
var test_log: Array[String] = []
var arena_type := "FOUNDRY FLOOR"
var battle_data: Dictionary = {}
var _arena_animation_active := false

func _ready() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	physics_test = OS.get_cmdline_user_args().has("--physics-test")
	rotation_test = OS.get_cmdline_user_args().has("--rotation-test")
	battle_controls_test = OS.get_cmdline_user_args().has("--battle-controls-test")
	auto_combat_test = OS.get_cmdline_user_args().has("--auto-combat-test")
	if auto_combat_test:
		countdown = 1.0
		time_left = 18.0
		battle_time_limit = 18.0
	battle_data = GameState.battle_definition(GameState.current_opponent)
	if not physics_test: GameState.current_arena_id = str(battle_data.arena)
	arena_type = "SCRAP PIT" if GameState.current_arena_id == "scrap_pit" else "FOUNDRY FLOOR"
	var arena_asset := "arenas/scrap-pit" if GameState.current_arena_id == "scrap_pit" else "arenas/foundry-floor"
	_arena_animation_active = ArtAssets.mount_animation_visual(self, arena_asset, VIEW, VIEW * 0.5)
	_build_arena()
	_spawn_battle()
	_build_ui()
	player.core_destroyed.connect(_on_core_destroyed)
	enemy.core_destroyed.connect(_on_core_destroyed)
	initial_player_x = player.core.global_position.x
	initial_enemy_x = enemy.core.global_position.x
	crank_rotation_start = player.crank_axle.rotation
	if rotation_test:
		_run_rotation_test()
	if physics_test:
		print("PHYSICS_TEST_BEGIN")
		get_tree().create_timer(2.0, false).timeout.connect(_log_physics_crank_sample)
		get_tree().create_timer(3.0, false).timeout.connect(_run_test_attacks)
		get_tree().create_timer(8.0, false).timeout.connect(_print_physics_test_summary)
	if battle_controls_test:
		if GameState.battle_control_test_stage == 0:
			call_deferred("_run_battle_controls_test")
		else:
			GameState.battle_control_test_stage = 0
			var restart_ok := not get_tree().paused and is_equal_approx(Engine.time_scale, 1.0) and is_instance_valid(player) and is_instance_valid(enemy)
			print("BATTLE_CONTROL_TEST restart_restores_speed_pause_and_scene=", restart_ok)
			_finish_test_cleanup(0 if restart_ok else 1)
	if auto_combat_test:
		get_tree().create_timer(2.0, false).timeout.connect(_log_auto_combat_sample)
		get_tree().create_timer(20.0, false).timeout.connect(_report_auto_combat_test)

func _build_arena() -> void:
	var floor_body := StaticBody2D.new()
	floor_body.name = "FoundryFloor"
	floor_body.add_to_group("drivable_surface")
	floor_body.position = Vector2(640, 604)
	add_child(floor_body)
	var floor_shape := CollisionShape2D.new()
	var floor_rect := RectangleShape2D.new()
	floor_rect.size = Vector2(1180, 44)
	floor_shape.shape = floor_rect
	floor_body.add_child(floor_shape)
	if GameState.current_arena_id == "scrap_pit":
		for ramp_data in [[Vector2(176,572),-0.14],[Vector2(1104,572),0.14]]:
			var ramp := StaticBody2D.new()
			ramp.name = "ScrapHeapRamp"
			ramp.add_to_group("drivable_surface")
			ramp.position = ramp_data[0]
			ramp.rotation = float(ramp_data[1])
			add_child(ramp)
			var ramp_shape := CollisionShape2D.new()
			var ramp_box := RectangleShape2D.new()
			ramp_box.size = Vector2(90,22)
			ramp_shape.shape = ramp_box
			ramp.add_child(ramp_shape)
	for x in [75.0, 1205.0]:
		var wall := StaticBody2D.new()
		wall.name = "ArenaBoundary"
		wall.position = Vector2(x, 440)
		add_child(wall)
		var wall_shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = Vector2(32, 360)
		wall_shape.shape = box
		wall.add_child(wall_shape)

func _spawn_battle() -> void:
	var selected_build: Dictionary = GameState.selected_build()
	if physics_test:
		selected_build = {"chassis":"CH-01","name":"Crank-Leg Physics Test","parts":{
			"drive_left":{"id":"MV-04","rotation":0,"level":1},
			"drive_right":{"id":"MV-01","rotation":0,"level":1},
			"front_weapon":{"id":"WP-04","rotation":0,"level":1}
		}}
	if rotation_test:
		selected_build = {"chassis":"CH-01","name":"Rotation Regression Fixture","parts":{
			"drive_left":{"id":"MV-04","rotation":180},
			"drive_right":{"id":"MV-01","rotation":270},
			"front_weapon":{"id":"WP-04","rotation":90},
			"upper_armor":{"id":"AR-02","rotation":180},
			"rear_utility":{"id":"UT-01","rotation":270}
		}}
	var enemy_build: Dictionary = battle_data.build.duplicate(true)
	if rotation_test:
		var ai_rotations := {"drive_left":90,"drive_right":180,"front_weapon":270,"upper_armor":90,"side_armor_left":180,"rear_utility":270}
		for socket_id in enemy_build.parts:
			if ai_rotations.has(socket_id): enemy_build.parts[socket_id].rotation = ai_rotations[socket_id]
	player = VEHICLE_SCRIPT.new()
	player.name = "PlayerMachine"
	player.position = Vector2(360, 520)
	player.is_player = true
	player.chassis_id = "CH-01" if physics_test else str(selected_build.get("chassis", "CH-01"))
	player.build_config = selected_build.duplicate(true)
	player.drive_direction = 1.0
	player.drive_torque = 11800.0
	player.crank_torque = 4200.0
	player.component_health = 48.0
	add_child(player)
	enemy = VEHICLE_SCRIPT.new()
	enemy.name = "AI_" + str(battle_data.archetype_name)
	enemy.position = Vector2(920, 520)
	enemy.is_player = false
	enemy.chassis_id = str(enemy_build.chassis)
	enemy.build_config = enemy_build.duplicate(true)
	enemy.drive_direction = -1.0
	enemy.drive_torque = 11600.0
	enemy.crank_torque = 3900.0
	enemy.component_health = 48.0
	add_child(enemy)
	player.target = enemy
	enemy.target = player
	player.component_disabled.connect(_on_component_disabled)
	enemy.component_disabled.connect(_on_component_disabled)
	if physics_test:
		enemy.position = Vector2(1120, 490)
		enemy.core.freeze = true
		enemy.target = null
		for wheel in enemy.wheels: wheel.freeze = true
		enemy.crank_axle.freeze = true
		enemy.crank_leg.freeze = true
		for weapon_id in ["drill", "saw", "hammer", "rocket"]:
			enemy.disabled[weapon_id] = true
			if enemy.weapon_nodes.has(weapon_id) and enemy.weapon_nodes[weapon_id] is Area2D:
				enemy.weapon_nodes[weapon_id].monitoring = false
	var mounted: Array[String] = []
	for item in selected_build.get("parts", {}).values(): mounted.append(str(item.get("id", "")))
	print("BATTLE_LOADOUT chassis=", player.chassis_id, " slot=", GameState.selected_slot + 1, " parts=", ",".join(PackedStringArray(mounted)), " configured=", not player.build_config.is_empty())
	var enemy_parts: Array[String] = []
	for item in enemy_build.get("parts", {}).values(): enemy_parts.append(str(item.get("id", ""))+"@L"+str(item.get("level",1)))
	print("CAMPAIGN_OPPONENT id=", battle_data.number, " name=", battle_data.name, " archetype=", battle_data.archetype, " arena=", battle_data.arena, " boss=", battle_data.boss, " ai_chassis=", enemy.chassis_id, " parts=", ",".join(PackedStringArray(enemy_parts)), " valid=", GameState.validate_build(enemy_build,GameState._campaign_owned_before(GameState.current_opponent)).is_empty())

func _angle_matches(actual: float, expected: float) -> bool:
	return absf(wrapf(actual - expected, -PI, PI)) < 0.002

func _run_rotation_test() -> void:
	var player_parts: Dictionary = player.build_config.get("parts", {})
	var player_weapon_degrees := int(player_parts.get("front_weapon", {}).get("rotation", 0))
	var player_angle := deg_to_rad(float(player_weapon_degrees))
	var player_drive_left: Dictionary = player_parts.get("drive_left", {})
	var player_drive_right: Dictionary = player_parts.get("drive_right", {})
	var player_armor: Dictionary = player_parts.get("upper_armor", {})
	var player_utility: Dictionary = player_parts.get("rear_utility", {})
	var player_crank_degrees := int(player_drive_left.get("rotation", player_drive_right.get("rotation", 0)))
	var player_ok := _angle_matches(player.front_weapon_mount.rotation, player_angle)
	player_ok = player_ok and _angle_matches(player.hammer_body.rotation, player_angle)
	player_ok = player_ok and _angle_matches(player.wheels[1].rotation, deg_to_rad(float(player_drive_right.get("rotation", 0))))
	player_ok = player_ok and _angle_matches(player.armor_nodes["armor_upper_armor"].rotation, deg_to_rad(float(player_armor.get("rotation", 0))))
	player_ok = player_ok and _angle_matches(player.shock_absorber_body.rotation, deg_to_rad(float(player_utility.get("rotation", 0))))
	player_ok = player_ok and _angle_matches(player.crank_axle.rotation, deg_to_rad(float(player_crank_degrees)))
	var expected_drill := player.front_weapon_mount.to_global(Vector2(player.drive_direction * 29.0, -3.0))
	player_ok = player_ok and player.weapon_nodes["drill"].global_position.distance_to(expected_drill) < 0.01
	player._fire_rocket(player.drive_direction)
	var expected_rocket_direction := Vector2(player.drive_direction, 0.0).rotated(player.front_weapon_mount.global_rotation).normalized()
	player_ok = player_ok and player.last_rocket_direction.distance_to(expected_rocket_direction) < 0.001
	var ai_parts: Dictionary = enemy.build_config.get("parts", {})
	var ai_front := deg_to_rad(float(ai_parts.get("front_weapon", {}).get("rotation", 0)))
	var ai_ok := _angle_matches(enemy.front_weapon_mount.rotation, ai_front)
	ai_ok = ai_ok and _angle_matches(enemy.hammer_body.rotation, ai_front)
	ai_ok = ai_ok and _angle_matches(enemy.wheels[0].rotation, deg_to_rad(float(ai_parts.get("drive_left", {}).get("rotation", 0))))
	ai_ok = ai_ok and _angle_matches(enemy.armor_nodes["armor_upper_armor"].rotation, deg_to_rad(float(ai_parts.get("upper_armor", {}).get("rotation", 0))))
	ai_ok = ai_ok and _angle_matches(enemy.shock_absorber_body.rotation, deg_to_rad(float(ai_parts.get("rear_utility", {}).get("rotation", 0))))
	print("ROTATION_ARENA_TEST player_mounts=", player_ok, " ai_mounts=", ai_ok, " player_weapon_deg=", player_weapon_degrees, " ai_weapon_deg=", int(ai_parts.get("front_weapon", {}).get("rotation", 0)), " configured_build=true")
	var passed := player_ok and ai_ok
	print("ROTATION_ARENA_TEST_PASS result=", passed)
	_finish_test_cleanup(0 if passed else 1)

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 5
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	var top := _panel(Rect2(22, 14, 1236, 112), Color(0.07, 0.10, 0.12, 0.95))
	ui.add_child(top)
	var title := _label("SCRAP WARS", 24, Color("f1c368"))
	title.position = Vector2(22, 17)
	top.add_child(title)
	var arena_label := _label("BATTLE %02d  ·  %s\n%s" % [GameState.current_opponent, str(battle_data.name).to_upper(), arena_type], 13, Color("b9c5c0"))
	arena_label.position = Vector2(22, 51)
	top.add_child(arena_label)
	player_bar = _progress(top, Rect2(325, 42, 230, 28), player.max_health, Color("6fc58b"))
	var pl := _label("YOUR CORE", 14, Color("d9e1dc"))
	pl.position = Vector2(325, 13)
	top.add_child(pl)
	enemy_bar = _progress(top, Rect2(735, 42, 230, 28), enemy.max_health, Color("df7258"))
	var el := _label("AI · " + str(battle_data.archetype_name).to_upper(), 14, Color("d9e1dc"))
	el.position = Vector2(735, 13)
	top.add_child(el)
	timer_label = _label("3", 32, Color("fff1c4"))
	timer_label.position = Vector2(604, 18)
	timer_label.custom_minimum_size = Vector2(80, 48)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(timer_label)
	status_label = _label("COUNTDOWN", 12, Color("bec9c6"))
	status_label.position = Vector2(594, 76)
	status_label.custom_minimum_size = Vector2(100, 22)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_child(status_label)
	var bottom := _panel(Rect2(22, 590, 1236, 112), Color(0.07, 0.10, 0.12, 0.96))
	ui.add_child(bottom)
	var helper_text := "AUTO BATTLE · BOTH MACHINES USE THE SAME PHYSICS" if not physics_test else "PHYSICS TEST · apply real strikes, damage, and knockback"
	var hint := _label(helper_text + "     ·     − / + changes battle speed", 13, Color("b9c5c0"))
	hint.position = Vector2(22, 10)
	hint.custom_minimum_size = Vector2(1160, 24)
	bottom.add_child(hint)
	if physics_test:
		_add_button(bottom, "HIT AI", Vector2(20, 53), Vector2(94, 48), _test_hit_enemy)
		_add_button(bottom, "HIT PLAYER", Vector2(122, 53), Vector2(118, 48), _test_hit_player)
		_add_button(bottom, "KNOCKBACK", Vector2(248, 53), Vector2(126, 48), _test_knockback)
		_add_button(bottom, "WEAPON TEST", Vector2(382, 53), Vector2(190, 48), _test_all_weapons)
	_add_button(bottom, "−", Vector2(650, 53), Vector2(56, 48), func(): _adjust_speed(-1))
	speed_readout = _label("SPEED 1.0×", 14, Color("f3d28a"))
	speed_readout.position = Vector2(712, 61)
	speed_readout.custom_minimum_size = Vector2(108, 30)
	speed_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bottom.add_child(speed_readout)
	_add_button(bottom, "+", Vector2(826, 53), Vector2(56, 48), func(): _adjust_speed(1))
	pause_button = _add_button(bottom, "PAUSE", Vector2(892, 53), Vector2(124, 48), _toggle_pause)
	_add_button(bottom, "RESTART", Vector2(1026, 53), Vector2(187, 48), _reset_battle)
	result_label = _label("", 34, Color("ffe4a0"))
	result_label.position = Vector2(290, 214)
	result_label.custom_minimum_size = Vector2(700, 170)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ui.add_child(result_label)
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.visible = false
	ui.add_child(pause_overlay)
	var scrim := ColorRect.new()
	scrim.color = Color(0.01, 0.02, 0.025, 0.78)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(scrim)
	var pause_card := _panel(Rect2(344, 170, 592, 380), Color(0.08, 0.11, 0.13, 0.99))
	pause_overlay.add_child(pause_card)
	var pause_title := _label("BATTLE PAUSED", 29, Color("f1c368"))
	pause_title.position = Vector2(41, 34)
	pause_title.custom_minimum_size = Vector2(510, 50)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(pause_title)
	var pause_note := _label("The arena is frozen. Resume or restart the fight.", 15, Color("c3cfca"))
	pause_note.position = Vector2(36, 93)
	pause_note.custom_minimum_size = Vector2(520, 34)
	pause_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_card.add_child(pause_note)
	_add_button(pause_card, "RESUME", Vector2(84, 181), Vector2(190, 58), _toggle_pause)
	_add_button(pause_card, "RESTART", Vector2(318, 181), Vector2(190, 58), _reset_battle)
	var pause_speed_note := _label("Use − / + below the arena to slow down or speed up.", 14, Color("aebbb6"))
	pause_speed_note.position = Vector2(367, 467)
	pause_speed_note.custom_minimum_size = Vector2(540, 28)
	pause_speed_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_overlay.add_child(pause_speed_note)
	_update_speed_readout()

func _panel(rect: Rect2, color: Color) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = Color("92713e")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	p.add_theme_stylebox_override("panel", sb)
	return p

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l

func _progress(parent: Node, rect: Rect2, maximum: float, fill: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.position = rect.position
	b.size = rect.size
	b.max_value = maximum
	b.value = maximum
	b.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("29373a")
	bg.set_corner_radius_all(5)
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.set_corner_radius_all(5)
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fg)
	parent.add_child(b)
	return b

func _add_button(parent: Node, caption: String, at: Vector2, size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = caption
	b.position = at
	var touch_size := Vector2(maxf(size.x, 64.0), maxf(size.y, 48.0))
	b.size = touch_size
	b.custom_minimum_size = touch_size
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("34444a")
	normal.border_color = Color("b48749")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	b.add_theme_stylebox_override("normal", normal)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("795f37")
	pressed.set_corner_radius_all(5)
	b.add_theme_stylebox_override("pressed", pressed)
	ArtAssets.apply_button_textures(b, ArtAssets.button_key_from_text(caption))
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _process(delta: float) -> void:
	if paused or ended:
		return
	test_elapsed += delta
	if is_instance_valid(player) and is_instance_valid(enemy):
		max_player_advance = maxf(max_player_advance, player.core.global_position.x - initial_player_x)
		max_enemy_advance = maxf(max_enemy_advance, initial_enemy_x - enemy.core.global_position.x)
		max_crank_contacts = maxi(max_crank_contacts, player.crank_leg.get_contact_count())
	if countdown > 0.0:
		countdown -= delta
		timer_label.text = str(maxi(1, ceili(countdown)))
		status_label.text = "COUNTDOWN"
		if countdown <= 0.0:
			status_label.text = "FIGHT!"
			await get_tree().create_timer(0.8).timeout
		return
	time_left -= delta
	timer_label.text = "%.1f" % maxf(time_left, 0.0)
	status_label.text = "FIGHT!"
	if is_instance_valid(player) and is_instance_valid(enemy):
		player_bar.value = player.health
		enemy_bar.value = enemy.health
		if not ended and (player.core.global_position.x < 55 or player.core.global_position.x > 1225 or player.core.global_position.y > 760):
			_finish(false, "PLAYER KNOCKED OUT OF ARENA")
		elif not ended and (enemy.core.global_position.x < 55 or enemy.core.global_position.x > 1225 or enemy.core.global_position.y > 760):
			_finish(true, "AI KNOCKED OUT OF ARENA")
	if time_left <= 0.0 and not ended:
		var player_pct := player.health / maxf(player.max_health,1.0)
		var enemy_pct := enemy.health / maxf(enemy.max_health,1.0)
		if player_pct > enemy_pct + 0.01: _finish(true, "TIMEOUT · HIGHER CORE HEALTH")
		elif enemy_pct > player_pct + 0.01: _finish(false, "TIMEOUT · AI HIGHER CORE HEALTH")
		elif player.total_component_health() > enemy.total_component_health() + 0.1: _finish(true, "TIMEOUT · CORE TIED, MORE PART HEALTH")
		elif enemy.total_component_health() > player.total_component_health() + 0.1: _finish(false, "TIMEOUT · CORE TIED, AI MORE PART HEALTH")
		else: _finish(false, "TIMEOUT · HEALTH TIED", true)

func _finish(won: bool, reason: String, is_draw := false) -> void:
	if ended: return
	ended = true
	paused = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	speed_index = 2
	if is_instance_valid(pause_overlay): pause_overlay.visible = false
	if is_instance_valid(pause_button): pause_button.text = "PAUSE"
	_update_speed_readout()
	if is_instance_valid(player): player.stop_effect_audio()
	if is_instance_valid(enemy): enemy.stop_effect_audio()
	var reward := GameState.grant_battle_reward(won, is_draw)
	result_text = ("DRAW" if is_draw else ("VICTORY" if won else "DEFEAT")) + "\n" + reason
	var reward_text := ""
	for component_id in GameState.last_equipment_rewards:
		reward_text += "\n+ " + str(GameState.PARTS[component_id].name)
	if won and GameState.last_equipment_rewards.is_empty() and reward == 0: reward_text = "\nFIRST-CLEAR REWARDS ALREADY CLAIMED"
	result_label.text = result_text + "\nBATTLE TIME %.1fS\n+%d SCRAP" % [battle_time_limit-time_left,reward] + reward_text
	_add_button(ui, "REPLAY", Vector2(365, 390), Vector2(170, 52), _reset_battle)
	_add_button(ui, "GARAGE", Vector2(555, 390), Vector2(170, 52), func(): GameState.return_screen="garage"; get_tree().change_scene_to_file("res://scenes/main.tscn"))
	_add_button(ui, "CONTINUE" if won and GameState.current_opponent < 12 else "CAMPAIGN", Vector2(745, 390), Vector2(210, 52), func(): _return_to_campaign(won))
	status_label.text = "BATTLE OVER"
	print("BATTLE_END ", result_text.replace("\n", " | "), " duration_s=", snappedf(battle_time_limit-time_left,0.1), " reward_scrap=", reward, " equipment=", ",".join(PackedStringArray(GameState.last_equipment_rewards)))
	if auto_combat_test:
		call_deferred("_report_auto_combat_test")

func _return_to_campaign(won: bool) -> void:
	if won: GameState.current_opponent = mini(GameState.completed_battles + 1, 12)
	GameState.current_arena_id=str(GameState.battle_definition(GameState.current_opponent).arena)
	GameState.return_screen="campaign"
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_core_destroyed(v: ScrapVehicle) -> void:
	_finish(v != player, "CORE DESTROYED")

func _on_component_disabled(v: ScrapVehicle, component_id: String) -> void:
	print("COMPONENT_DISABLED team=", "player" if v.is_player else "AI", " part=", component_id)
	if is_instance_valid(status_label): status_label.text = "PART DISABLED: " + component_id.to_upper()

func _test_hit_enemy() -> void:
	if is_instance_valid(enemy): enemy.take_hit(42.0, "wheel_left", "test_control", 1.0)

func _test_hit_player() -> void:
	if is_instance_valid(player): player.take_hit(42.0, "wheel_left", "test_control", -1.0)

func _test_knockback() -> void:
	if is_instance_valid(enemy): enemy.core.apply_central_impulse(Vector2(520.0, -170.0))

func _test_all_weapons() -> void:
	if not is_instance_valid(player) or not is_instance_valid(enemy): return
	for weapon in ["drill", "saw", "hammer"]:
		player._on_weapon_body_entered(enemy.core, weapon)
	player._fire_rocket(1.0)
	status_label.text = "WEAPON TEST FIRED"

func _run_test_attacks() -> void:
	if not physics_test: return
	# The same public damage and physical impulse routines used by combat are exercised here.
	_test_all_weapons()
	await get_tree().create_timer(0.25).timeout
	_test_hit_enemy()
	await get_tree().create_timer(0.25).timeout
	_test_knockback()
	await get_tree().create_timer(0.25).timeout
	_test_hit_enemy()
	await get_tree().create_timer(0.25).timeout
	_test_hit_enemy()
	print("TEST_ACTIONS_COMPLETE")

func _print_physics_test_summary() -> void:
	if not physics_test or not is_instance_valid(player): return
	var displacement := player.core.global_position.x - initial_player_x
	var axle_turn := player.crank_turn_total
	var disabled_count := 0
	for value in enemy.disabled.values():
		if value: disabled_count += 1
	print("PHYSICS_METRICS displacement_px=", snappedf(displacement, 0.1), " crank_cumulative_rotation_rad=", snappedf(axle_turn, 0.01), " crank_revolutions=", snappedf(axle_turn / TAU, 0.01), " max_crank_leg_floor_contacts=", max_crank_contacts, " rocket_count=", player.launched_rockets, " enemy_disabled_components=", disabled_count, " battle_ended=", ended)
	print("BATTLE_FX_METRICS ", BattleFX.metrics_snapshot())
	print("BATTLE_AUDIO_LOOPS player_engine_loaded=", player.engine_sound.stream != null, " player_engine_started=", player.engine_loop_started, " player_rotary_loaded=", player.rotary_sound.stream != null, " player_rotary_started=", player.rotary_loop_started, " enemy_engine_loaded=", enemy.engine_sound.stream != null, " player_engine_playing_at_summary=", player.engine_sound.playing)
	if physics_test:
		_finish_test_cleanup(0)

func _finish_test_cleanup(exit_code: int) -> void:
	var tree := get_tree()
	if is_instance_valid(player): player.release_effect_audio()
	if is_instance_valid(enemy): enemy.release_effect_audio()
	BattleFX.dispose_transient_effects()
	var test_scene := tree.current_scene
	if is_instance_valid(test_scene): test_scene.queue_free()
	tree.create_timer(0.25).timeout.connect(Callable(tree, "quit").bind(exit_code), CONNECT_ONE_SHOT)

func _toggle_pause() -> void:
	if ended:
		return
	paused = not paused
	get_tree().paused = paused
	status_label.text = "PAUSED" if paused else "FIGHT!"
	if is_instance_valid(pause_overlay): pause_overlay.visible = paused
	if is_instance_valid(pause_button): pause_button.text = "RESUME" if paused else "PAUSE"

func _adjust_speed(direction: int) -> void:
	if ended:
		return
	speed_index = clampi(speed_index + direction, 0, BATTLE_SPEEDS.size() - 1)
	Engine.time_scale = float(BATTLE_SPEEDS[speed_index])
	_update_speed_readout()

func _update_speed_readout() -> void:
	if is_instance_valid(speed_readout):
		speed_readout.text = "SPEED " + str(BATTLE_SPEEDS[speed_index]) + "×"

func _reset_battle() -> void:
	get_tree().paused = false
	paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()

func _run_battle_controls_test() -> void:
	_adjust_speed(-99)
	var slow_ok := is_equal_approx(Engine.time_scale, 0.5)
	_adjust_speed(99)
	var fast_ok := is_equal_approx(Engine.time_scale, 2.0)
	_adjust_speed(-3)
	var normal_ok := is_equal_approx(Engine.time_scale, 1.0)
	_toggle_pause()
	var pause_ok := paused and get_tree().paused and pause_overlay.visible
	_toggle_pause()
	var resume_ok := not paused and not get_tree().paused and not pause_overlay.visible
	print("BATTLE_CONTROL_TEST slow=", slow_ok, " fast=", fast_ok, " normal=", normal_ok, " pause=", pause_ok, " resume=", resume_ok)
	if not (slow_ok and fast_ok and normal_ok and pause_ok and resume_ok):
		get_tree().quit(1)
		return
	GameState.battle_control_test_stage = 1
	_reset_battle()

func _log_auto_combat_sample() -> void:
	if not auto_combat_test or ended or not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	var p_joint := get_node_or_null("WheelPin_0") as PinJoint2D
	print("AUTO_COMBAT_SAMPLE t=", snappedf(test_elapsed, 0.1), " p_pos=", player.core.global_position, " p_v=", player.core.linear_velocity, " p_drive=", player.last_drive_input, " p_torque=", player.drive_torque, " p_core_frozen=", player.core.freeze, " p_wheel_disabled=", player.disabled.get("wheel_left"), " p_wheel_frozen=", player.wheels[0].freeze, " p_wheel_mass=", player.wheels[0].mass, " p_wheel_pos=", player.wheels[0].global_position, " p_wheel_v=", player.wheels[0].linear_velocity, " p_wheel_rot=", player.wheels[0].rotation, " p_wheel_w=", player.wheels[0].angular_velocity, " p_contacts=", player.wheels[0].get_contact_count(), " p_joint_a=", p_joint.node_a if p_joint else "", " p_joint_b=", p_joint.node_b if p_joint else "", " e_pos=", enemy.core.global_position, " e_v=", enemy.core.linear_velocity, " e_drive=", enemy.last_drive_input, " e_wheel_disabled=", enemy.disabled.get("wheel_left"), " e_wheel_frozen=", enemy.wheels[0].freeze, " e_wheel_pos=", enemy.wheels[0].global_position, " e_wheel_rot=", enemy.wheels[0].rotation, " e_contacts=", enemy.wheels[0].get_contact_count(), " e_wheel_w=", enemy.wheels[0].angular_velocity)
	if test_elapsed < 7.0:
		get_tree().create_timer(2.0, false).timeout.connect(_log_auto_combat_sample)

func _log_physics_crank_sample() -> void:
	if physics_test and is_instance_valid(player):
		print("PHYSICS_CRANK_SAMPLE core_pos=", player.core.global_position, " axle_rot=", snappedf(player.crank_axle.rotation,0.01), " axle_omega=", snappedf(player.crank_axle.angular_velocity,0.01), " crank_enabled=", not bool(player.disabled.get("crank_leg",true)), " leg_pos=", player.crank_leg.global_position, " leg_contacts=", player.crank_leg.get_contact_count(), " wheel_disabled=", player.disabled.get("wheel_left"), ",", player.disabled.get("wheel_right"))

func _report_auto_combat_test() -> void:
	if auto_combat_reported or not is_instance_valid(player) or not is_instance_valid(enemy):
		return
	auto_combat_reported = true
	var landed := player.attack_hits_landed + enemy.attack_hits_landed
	var damage := player.raw_damage_received + enemy.raw_damage_received
	var movement_ok := max_player_advance >= 30.0 and max_enemy_advance >= 30.0
	var combat_ok := landed > 0 and damage > 0.0
	var passed := movement_ok and combat_ok and ended
	print("AUTO_COMBAT_METRICS player_forward_px=", snappedf(max_player_advance, 0.1), " ai_forward_px=", snappedf(max_enemy_advance, 0.1), " player_pos=", player.core.global_position, " ai_pos=", enemy.core.global_position, " player_vx=", snappedf(player.core.linear_velocity.x, 0.1), " ai_vx=", snappedf(enemy.core.linear_velocity.x, 0.1), " player_wheel_omega=", snappedf(player.wheels[0].angular_velocity, 0.1), " ai_wheel_omega=", snappedf(enemy.wheels[0].angular_velocity, 0.1), " player_hits=", player.attack_hits_landed, " ai_hits=", enemy.attack_hits_landed, " player_damage=", snappedf(player.raw_damage_received, 0.1), " ai_damage=", snappedf(enemy.raw_damage_received, 0.1), " player_rockets=", player.launched_rockets, " ai_rockets=", enemy.launched_rockets, " ended=", ended)
	print("AUTO_COMBAT_TEST_PASS result=", passed)
	_finish_test_cleanup(0 if passed else 1)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE: _toggle_pause()
			KEY_R: _reset_battle()
			KEY_1: if is_instance_valid(player) and is_instance_valid(enemy): player._on_weapon_body_entered(enemy.core, "drill")
			KEY_2: if is_instance_valid(player) and is_instance_valid(enemy): player._on_weapon_body_entered(enemy.core, "saw")
			KEY_3: if is_instance_valid(player) and is_instance_valid(enemy): player._on_weapon_body_entered(enemy.core, "hammer")
			KEY_4: _test_all_weapons()

func _draw() -> void:
	var arena_asset := "arenas/scrap-pit" if GameState.current_arena_id == "scrap_pit" else "arenas/foundry-floor"
	if _arena_animation_active or ArtAssets.draw_texture(self, arena_asset, Rect2(Vector2.ZERO, VIEW)):
		return
	# The original procedural arena remains the fallback when no replacement image exists.
	var scrap_pit := GameState.current_arena_id == "scrap_pit"
	draw_rect(Rect2(Vector2.ZERO, VIEW), Color("241f20") if scrap_pit else Color("18242a"), true)
	for y in range(150, 580, 55):
		draw_line(Vector2(0, y), Vector2(1280, y), Color(0.4, 0.27, 0.24, 0.18) if scrap_pit else Color(0.25, 0.33, 0.34, 0.22), 1.0)
	for i in range(14):
		var x := float(i) * 100.0
		draw_rect(Rect2(Vector2(x, 145), Vector2(34, 90 + float(i % 3) * 24)), Color("362c2a") if scrap_pit else Color("202e33"), true)
		draw_rect(Rect2(Vector2(x + 7, 156), Vector2(8, 62)), Color("685043") if scrap_pit else Color("34454a"), true)
		draw_circle(Vector2(x + 17, 257), 5, Color(0.96, 0.55, 0.31, 0.45) if scrap_pit else Color(0.96, 0.69, 0.31, 0.45))
	if scrap_pit:
		# Scrap heaps stay outside the playable flat floor; they are background silhouettes only.
		for pile in [[Vector2(48,560),Vector2(70,466),Vector2(115,560)],[Vector2(165,560),Vector2(200,485),Vector2(243,560)],[Vector2(1030,560),Vector2(1078,478),Vector2(1126,560)],[Vector2(1144,560),Vector2(1182,449),Vector2(1230,560)]]:
			draw_colored_polygon(PackedVector2Array(pile),Color("59443a"))
			draw_line(pile[0]+Vector2(15,-12),pile[1],Color("987452"),4)
	# Foundry lamps and their warm cones.
	for x in [170.0, 445.0, 835.0, 1110.0]:
		draw_line(Vector2(x, 0), Vector2(x, 78), Color("586367"), 5.0)
		draw_rect(Rect2(Vector2(x - 24, 72), Vector2(48, 11)), Color("f1bd66"), true)
		draw_colored_polygon(PackedVector2Array([Vector2(x - 20, 83),Vector2(x - 105, 410),Vector2(x + 105, 410)]), Color(0.96, 0.68, 0.32, 0.035))
	# Heavy plate floor, hazard stripes, and knockout margins.
	draw_rect(Rect2(Vector2(50, 580), Vector2(1180, 66)), Color("64514a") if scrap_pit else Color("485357"), true)
	draw_rect(Rect2(Vector2(50, 580), Vector2(1180, 7)), Color("c27649") if scrap_pit else Color("d4a14b"), true)
	for x in range(62, 1230, 36):
		draw_colored_polygon(PackedVector2Array([Vector2(x, 646),Vector2(x + 18, 646),Vector2(x + 48, 580),Vector2(x + 30, 580)]), Color("343e40"))
	draw_rect(Rect2(Vector2(50, 574), Vector2(55, 8)), Color("f0654b"), true)
	draw_rect(Rect2(Vector2(1175, 574), Vector2(55, 8)), Color("f0654b"), true)
	draw_line(Vector2(640, 580), Vector2(640, 646), Color("879091"), 2.0)
