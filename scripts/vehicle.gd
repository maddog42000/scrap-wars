extends Node2D
class_name ScrapVehicle

signal core_destroyed(vehicle: ScrapVehicle)
signal component_disabled(vehicle: ScrapVehicle, component_id: String)

const CORE_SCRIPT := preload("res://scripts/core_draw.gd")
const WHEEL_SCRIPT := preload("res://scripts/wheel_draw.gd")
const CRANK_SCRIPT := preload("res://scripts/crank_draw.gd")
const HAMMER_SCRIPT := preload("res://scripts/hammer_draw.gd")
const MODULE_SCRIPT := preload("res://scripts/module_draw.gd")
const PROJECTILE_SCENE := preload("res://scenes/projectile.tscn")

@export var is_player := true
@export var chassis_id := "CH-01"
@export var drive_direction := 1.0
@export var drive_torque := 14500.0
@export var crank_torque := 3600.0
@export var component_health := 80.0
var build_config: Dictionary = {}
var core: RigidBody2D
var wheels: Array[RigidBody2D] = []
var wheel_joints: Array[PinJoint2D] = []
var crank_axle: RigidBody2D
var crank_axle_joint: PinJoint2D
var crank_leg: RigidBody2D
var crank_leg_joint: PinJoint2D
var hammer_body: RigidBody2D
var hammer_joint: PinJoint2D
var front_weapon_mount: Node2D
var front_weapon_rotation := 0.0
var booster_rotations: Array[float] = []
var weapon_nodes: Dictionary = {}
var health := 320.0
var max_health := 320.0
var comp_hp: Dictionary = {}
var disabled: Dictionary = {}
var last_fire := {"drill": 0.0, "saw": 0.0, "hammer": 0.0, "rocket": 0.0}
var elapsed := 0.0
var target: ScrapVehicle
var launched_rockets := 0
var last_rocket_direction := Vector2.ZERO
var attack_hits_landed := 0
var raw_damage_received := 0.0
var last_drive_input := 0.0
var crank_turn_total := 0.0
var booster_timer := 0.0
var booster_count := 0
var armor_nodes: Dictionary = {}
var counterweight_body: RigidBody2D
var shock_absorber_body: RigidBody2D
var ai_archetype := "rammer"
var alive := true
var _flash := 0.0
var engine_sound: AudioStreamPlayer2D
var rotary_sound: AudioStreamPlayer2D
var exhaust_particles: CPUParticles2D
var audio_enabled := true
var engine_loop_started := false
var rotary_loop_started := false
var _chassis_animation_active := false
var _parts := ["wheel_left", "wheel_right", "crank_leg", "drill", "saw", "hammer", "rocket", "armor"]

func _ready() -> void:
	add_to_group("vehicles")
	_build_core()
	_build_drive()
	_build_crank()
	_build_weapons()
	for id in _parts:
		comp_hp[id] = component_health
		disabled[id] = false
	if not build_config.is_empty():
		_configure_from_build()
	_setup_audio_feedback()

func _setup_audio_feedback() -> void:
	engine_sound = AudioStreamPlayer2D.new()
	engine_sound.name = "EngineLoop"
	engine_sound.max_distance = 2200.0
	engine_sound.attenuation = 0.4
	engine_sound.add_to_group("battle_loop_audio")
	var engine_stream := load("res://assets/audio/engine_rough_loop.mp3") as AudioStreamMP3
	if engine_stream != null:
		engine_stream.loop = true
		engine_sound.stream = engine_stream
	core.add_child(engine_sound)

	rotary_sound = AudioStreamPlayer2D.new()
	rotary_sound.name = "RotaryWeaponLoop"
	rotary_sound.max_distance = 2200.0
	rotary_sound.attenuation = 0.55
	rotary_sound.add_to_group("battle_loop_audio")
	var rotary_stream := load("res://assets/audio/rotary_tool_loop.mp3") as AudioStreamMP3
	if rotary_stream != null:
		rotary_stream.loop = true
		rotary_sound.stream = rotary_stream
	core.add_child(rotary_sound)

	exhaust_particles = BattleFX.create_engine_exhaust(core, Vector2(-drive_direction * 78.0, -12.0), -drive_direction)
	_update_audio_feedback()

func _update_audio_feedback() -> void:
	if not is_instance_valid(core):
		return
	var volume_enabled := audio_enabled and float(GameState.sfx_volume) > 0.001
	var speed := core.linear_velocity.length()
	if is_instance_valid(engine_sound):
		engine_sound.volume_db = linear_to_db(maxf(0.0001, float(GameState.sfx_volume) * (0.68 if is_player else 0.38)))
		engine_sound.pitch_scale = clampf(0.78 + speed / 720.0 + absf(crank_axle.angular_velocity) * 0.0018, 0.76, 1.48)
		if alive and volume_enabled and engine_sound.stream != null and not engine_sound.playing:
			engine_sound.play()
			engine_loop_started = true
		elif (not alive or not volume_enabled) and engine_sound.playing:
			engine_sound.stop()
	var rotary_active: bool = alive and volume_enabled and (not bool(disabled.get("drill", false)) or not bool(disabled.get("saw", false)))
	if is_instance_valid(rotary_sound):
		rotary_sound.volume_db = linear_to_db(maxf(0.0001, float(GameState.sfx_volume) * (0.23 if is_player else 0.14)))
		rotary_sound.pitch_scale = clampf(0.9 + absf(core.angular_velocity) * 0.07, 0.82, 1.4)
		if rotary_active and rotary_sound.stream != null and not rotary_sound.playing:
			rotary_sound.play()
			rotary_loop_started = true
		elif not rotary_active and rotary_sound.playing:
			rotary_sound.stop()
	if is_instance_valid(exhaust_particles):
		exhaust_particles.emitting = alive and audio_enabled
		exhaust_particles.speed_scale = clampf(0.62 + speed / 260.0, 0.62, 1.9)

func stop_effect_audio() -> void:
	audio_enabled = false
	if is_instance_valid(engine_sound): engine_sound.stop()
	if is_instance_valid(rotary_sound): rotary_sound.stop()
	if is_instance_valid(exhaust_particles): exhaust_particles.emitting = false

func release_effect_audio() -> void:
	stop_effect_audio()
	if is_instance_valid(engine_sound): engine_sound.stream = null
	if is_instance_valid(rotary_sound): rotary_sound.stream = null

func _component_world_position(part: String) -> Vector2:
	if armor_nodes.has(part) and is_instance_valid(armor_nodes[part]):
		return armor_nodes[part].global_position
	match part:
		"wheel_left": return wheels[0].global_position
		"wheel_right": return wheels[1].global_position
		"crank_leg": return crank_leg.global_position
		"drill": return weapon_nodes["drill"].global_position
		"saw": return weapon_nodes["saw"].global_position
		"hammer": return hammer_body.global_position
		"rocket": return front_weapon_mount.global_position
		"shock_absorber":
			if is_instance_valid(shock_absorber_body): return shock_absorber_body.global_position
		"counterweight":
			if is_instance_valid(counterweight_body): return counterweight_body.global_position
	return core.global_position

func _configure_from_build() -> void:
	var parts: Dictionary = build_config.get("parts", {})
	ai_archetype = str(build_config.get("archetype", "rammer"))
	var front_part: Dictionary = parts.get("front_weapon", {})
	front_weapon_rotation = _part_rotation(front_part)
	front_weapon_mount.rotation = front_weapon_rotation
	hammer_body.position = _front_point(Vector2(drive_direction * 108.0, -31.0))
	hammer_body.rotation = front_weapon_rotation
	hammer_joint.global_position = core.to_global(_front_point(Vector2(drive_direction * 78.0, -29.0)))
	var installed: Array[String] = []
	for entry in parts.values():
		var component_id := str(entry.id)
		installed.append(component_id)
		var level := GameState.component_level(entry, component_id)
		var base_hp := float(GameState.PARTS.get(component_id, {}).get("hp", component_health))
		var hp := base_hp * (1.0 + 0.18 * float(level - 1))
		if component_id.begins_with("MV-"):
			if parts.get("drive_left", {}).get("id", "") == component_id: comp_hp["wheel_left"] = hp
			if parts.get("drive_right", {}).get("id", "") == component_id: comp_hp["wheel_right"] = hp
			if component_id == "MV-04": comp_hp["crank_leg"] = hp
		elif component_id == "WP-01": comp_hp["drill"] = hp
		elif component_id == "WP-02": comp_hp["saw"] = hp
		elif component_id == "WP-03": comp_hp["hammer"] = hp
		elif component_id == "WP-04": comp_hp["rocket"] = hp
	var has_crank := false
	var crank_rotation := 0.0
	for i in 2:
		var socket_id := "drive_left" if i == 0 else "drive_right"
		var part: Dictionary = parts.get(socket_id, {})
		var component_id := str(part.get("id", ""))
		var wheel_key := "wheel_left" if i == 0 else "wheel_right"
		if component_id in ["MV-01", "MV-02", "MV-03", "MV-04"] and GameState.PARTS.has(component_id):
			wheels[i].call("set_asset_key", "components/locomotion/" + component_id.to_lower())
			wheels[i].mass = float(GameState.PARTS[component_id].mass)
			wheels[i].rotation = _part_rotation(part)
			if component_id == "MV-04":
				if not has_crank: crank_rotation = _part_rotation(part)
				has_crank = true
				disabled[wheel_key] = true
				wheels[i].freeze = true
				wheels[i].collision_layer = 0
				wheels[i].collision_mask = 0
				wheels[i].visible = false
				wheel_joints[i].queue_free()
			elif component_id == "MV-03":
				booster_count += 1
				booster_rotations.append(_part_rotation(part))
				disabled[wheel_key] = true
				wheels[i].freeze = true
				wheels[i].collision_layer = 0
				wheels[i].collision_mask = 0
				wheels[i].visible = false
				wheel_joints[i].queue_free()
			elif component_id == "MV-02":
				var material := PhysicsMaterial.new()
				material.friction = 1.7
				material.bounce = 0.02
				wheels[i].physics_material_override = material
		else:
			disabled[wheel_key] = true
			wheels[i].freeze = true
			wheels[i].collision_layer = 0
			wheels[i].collision_mask = 0
			wheels[i].visible = false
			wheel_joints[i].queue_free()
	if not has_crank:
		disabled["crank_leg"] = true
		crank_axle.freeze = true
		crank_leg.freeze = true
		crank_axle.collision_layer = 0
		crank_axle.collision_mask = 0
		crank_leg.collision_layer = 0
		crank_leg.collision_mask = 0
		crank_axle.visible = false
		crank_leg.visible = false
		crank_axle_joint.queue_free()
		crank_leg_joint.queue_free()
	else:
		crank_axle.visible = true
		crank_leg.visible = true
		_apply_crank_rotation(crank_rotation)
	for pair in [["drill","WP-01"],["saw","WP-02"],["hammer","WP-03"],["rocket","WP-04"]]:
		var weapon_id: String = pair[0]
		if not installed.has(pair[1]):
			disabled[weapon_id] = true
			if weapon_nodes.has(weapon_id) and weapon_nodes[weapon_id] is Area2D:
				weapon_nodes[weapon_id].monitoring = false
				weapon_nodes[weapon_id].visible = false
			if weapon_id == "hammer":
				hammer_body.collision_layer = 0
				hammer_body.collision_mask = 0
				hammer_body.freeze = true
				hammer_body.visible = false
				hammer_joint.queue_free()
	var has_armor := installed.has("AR-01") or installed.has("AR-02") or installed.has("AR-03")
	if not has_armor: disabled["armor"] = true
	for socket_id in parts:
		var component_id := str(parts[socket_id].get("id", ""))
		if component_id.begins_with("AR-"):
			var level := GameState.component_level(parts[socket_id], component_id)
			var armor_key := "armor_" + str(socket_id)
			comp_hp[armor_key] = float(GameState.PARTS[component_id].hp) * (1.0 + 0.18 * float(level - 1))
			disabled[armor_key] = false
			_build_armor(socket_id, component_id, _part_rotation(parts[socket_id]))
			comp_hp["armor"] = maxf(float(comp_hp.get("armor", 0.0)), float(comp_hp[armor_key]))
	var utility: Dictionary = parts.get("rear_utility", {})
	if not utility.is_empty():
		var utility_id := str(utility.get("id", ""))
		if utility_id == "UT-01":
			core.angular_damp = 3.2
			comp_hp["shock_absorber"] = float(GameState.PARTS[utility_id].hp)
			disabled["shock_absorber"] = false
			_build_shock_absorber(_part_rotation(utility))
		elif utility_id == "UT-02":
			comp_hp["counterweight"] = float(GameState.PARTS[utility_id].hp)
			disabled["counterweight"] = false
			_build_counterweight(_part_rotation(utility))
	var stats: Dictionary = GameState.build_stats(build_config)
	health = float(stats.core)
	max_health = health
	core.mass = float(GameState.CHASSIS[chassis_id].mass)
	drive_torque *= float(GameState.CHASSIS[chassis_id].drive)

func _build_armor(socket_id: String, component_id: String, mount_rotation: float) -> void:
	var body := RigidBody2D.new()
	body.name = "Armor_" + socket_id
	body.mass = float(GameState.PARTS[component_id].mass)
	body.position = _armor_position(socket_id)
	body.rotation = mount_rotation
	body.linear_damp = 0.4
	body.angular_damp = 0.5
	body.collision_layer = 1
	body.collision_mask = 1
	body.can_sleep = false
	body.set_meta("module_kind", "armor")
	body.set_meta("asset_key", "components/armor/" + component_id.to_lower())
	body.set_meta("owner", self)
	body.set_meta("component_key", "armor_" + socket_id)
	body.add_to_group("machine_components")
	body.set_script(MODULE_SCRIPT)
	var shape_node := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(30, 64) if socket_id == "front_weapon" else Vector2(46, 22)
	shape_node.shape = shape
	body.add_child(shape_node)
	core.add_child(body)
	_join(core, body, body.global_position, "ArmorMount_" + socket_id)
	armor_nodes["armor_" + socket_id] = body

func _armor_position(socket_id: String) -> Vector2:
	match socket_id:
		"front_weapon": return Vector2(drive_direction * 75.0, -2)
		"upper_armor": return Vector2(0, -38)
		"lower_armor": return Vector2(0, 38)
		"side_armor_left": return Vector2(-57, 0)
		"side_armor_right": return Vector2(57, 0)
	return Vector2.ZERO

func _build_counterweight(mount_rotation: float) -> void:
	counterweight_body = RigidBody2D.new()
	counterweight_body.name = "Counterweight"
	counterweight_body.position = Vector2(-drive_direction * 64, -31)
	counterweight_body.rotation = mount_rotation
	counterweight_body.mass = float(GameState.PARTS["UT-02"].mass)
	counterweight_body.collision_layer = 1
	counterweight_body.collision_mask = 1
	counterweight_body.can_sleep = false
	counterweight_body.set_meta("module_kind", "counterweight")
	counterweight_body.set_meta("asset_key", "components/utility/ut-02")
	counterweight_body.set_meta("owner", self)
	counterweight_body.set_meta("component_key", "counterweight")
	counterweight_body.add_to_group("machine_components")
	counterweight_body.set_script(MODULE_SCRIPT)
	var cshape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18
	cshape.shape = circle
	counterweight_body.add_child(cshape)
	core.add_child(counterweight_body)
	_join(core, counterweight_body, counterweight_body.global_position, "CounterweightPin")

func _build_shock_absorber(mount_rotation: float) -> void:
	shock_absorber_body = RigidBody2D.new()
	shock_absorber_body.name = "ShockAbsorber"
	shock_absorber_body.position = Vector2(-drive_direction * 60, -27)
	shock_absorber_body.rotation = mount_rotation
	shock_absorber_body.mass = float(GameState.PARTS["UT-01"].mass)
	shock_absorber_body.collision_layer = 1
	shock_absorber_body.collision_mask = 1
	shock_absorber_body.can_sleep = false
	shock_absorber_body.set_meta("module_kind", "shock")
	shock_absorber_body.set_meta("asset_key", "components/utility/ut-01")
	shock_absorber_body.set_meta("owner", self)
	shock_absorber_body.set_meta("component_key", "shock_absorber")
	shock_absorber_body.add_to_group("machine_components")
	shock_absorber_body.set_script(MODULE_SCRIPT)
	var cs := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(36, 18)
	cs.shape = box
	shock_absorber_body.add_child(cs)
	core.add_child(shock_absorber_body)
	_join(core, shock_absorber_body, shock_absorber_body.global_position, "ShockAbsorberPin")

func _build_core() -> void:
	core = RigidBody2D.new()
	core.name = "ChassisBody"
	core.position = Vector2.ZERO
	core.mass = 5.4 if chassis_id == "CH-02" else (10.0 if chassis_id == "CH-03" else 7.0)
	core.linear_damp = 0.14
	core.angular_damp = 1.15
	core.can_sleep = false
	core.collision_layer = 1
	core.collision_mask = 1
	core.add_to_group("machine_core")
	core.set_script(CORE_SCRIPT)
	var chassis_asset := "machines/chassis/" + chassis_id.to_lower()
	core.set_meta("asset_key", chassis_asset)
	add_child(core)
	var chassis_size := Vector2(150.0, 44.0) if chassis_id == "CH-02" else (Vector2(166.0, 72.0) if chassis_id == "CH-03" else Vector2(144.0, 56.0))
	_chassis_animation_active = ArtAssets.mount_animation_visual(core, chassis_asset, chassis_size)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(154, 56) if chassis_id != "CH-03" else Vector2(174, 70)
	shape.shape = rect
	core.add_child(shape)

func _new_circle_body(node_name: String, local_pos: Vector2, radius: float, mass_value: float, color: Color, draw_script: Script) -> RigidBody2D:
	var b := RigidBody2D.new()
	b.name = node_name
	b.position = local_pos
	b.mass = mass_value
	b.linear_damp = 0.08
	b.angular_damp = 0.06
	b.can_sleep = false
	b.collision_layer = 1
	b.collision_mask = 1
	if node_name.begins_with("PoweredWheel"):
		b.contact_monitor = true
		b.max_contacts_reported = 8
	b.set_meta("draw_color", color)
	b.set_script(draw_script)
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	cs.shape = circle
	b.add_child(cs)
	return b

func _join(a: Node2D, b: Node2D, anchor: Vector2, joint_name: String) -> PinJoint2D:
	var joint := PinJoint2D.new()
	joint.name = joint_name
	get_parent().add_child(joint)
	joint.global_position = anchor
	joint.node_a = joint.get_path_to(a)
	joint.node_b = joint.get_path_to(b)
	joint.disable_collision = true
	return joint

func _part_rotation(part: Dictionary) -> float:
	return deg_to_rad(float(wrapi(int(part.get("rotation", 0)), 0, 360)))

func _front_point(unrotated_core_point: Vector2) -> Vector2:
	var pivot := Vector2(drive_direction * 75.0, -2.0)
	return pivot + (unrotated_core_point - pivot).rotated(front_weapon_rotation)

func _build_drive() -> void:
	var offsets := [Vector2(-50, 34), Vector2(50, 34)]
	for i in 2:
		var wid := "wheel_left" if i == 0 else "wheel_right"
		var w := _new_circle_body("PoweredWheel_" + str(i), offsets[i], 27 if chassis_id != "CH-02" else 23, 1.5, Color("26343c") if wid == "wheel_left" else Color("34464b"), WHEEL_SCRIPT)
		w.set_meta("component_id", wid)
		w.set_meta("asset_key", "components/locomotion/mv-01")
		core.add_child(w)
		wheels.append(w)
		wheel_joints.append(_join(core, w, w.global_position, "WheelPin_" + str(i)))

func _build_crank() -> void:
	crank_axle = _new_circle_body("CrankAxle", Vector2(drive_direction * 57, 31), 13, 1.1, Color("d79b36"), CRANK_SCRIPT)
	crank_axle.set_meta("kind", "axle")
	crank_axle.set_meta("asset_key", "components/locomotion/crank-axle")
	core.add_child(crank_axle)
	crank_axle_joint = _join(core, crank_axle, crank_axle.global_position, "CrankAxlePin")
	crank_leg = RigidBody2D.new()
	crank_leg.name = "CrankLegAndFoot"
	crank_leg.position = Vector2(drive_direction * 69, 46)
	crank_leg.mass = 2.1
	crank_leg.linear_damp = 0.08
	crank_leg.angular_damp = 0.08
	crank_leg.can_sleep = false
	crank_leg.contact_monitor = true
	crank_leg.max_contacts_reported = 8
	crank_leg.collision_layer = 1
	crank_leg.collision_mask = 1
	crank_leg.set_meta("kind", "leg")
	crank_leg.set_meta("asset_key", "components/locomotion/crank-leg")
	crank_leg.set_script(CRANK_SCRIPT)
	var leg_shape := CollisionShape2D.new()
	var leg_box := RectangleShape2D.new()
	leg_box.size = Vector2(14, 30)
	leg_shape.shape = leg_box
	crank_leg.add_child(leg_shape)
	crank_leg.set_meta("kind", "leg")
	core.add_child(crank_leg)
	crank_leg_joint = _join(crank_axle, crank_leg, crank_axle.global_position + Vector2(drive_direction * 12, 0), "EccentricLegHinge")

func _apply_crank_rotation(mount_rotation: float) -> void:
	crank_axle.rotation = mount_rotation
	crank_leg.rotation = mount_rotation
	var eccentric := Vector2(drive_direction * 12.0, 0.0).rotated(mount_rotation)
	var leg_pivot := crank_axle.position + eccentric
	crank_leg.position = leg_pivot + Vector2(0.0, 15.0).rotated(mount_rotation)
	crank_leg_joint.global_position = core.to_global(leg_pivot)

func _make_sensor(weapon_id: String, local_pos: Vector2, radius: float, parent_override: Node2D = null) -> Area2D:
	var area := Area2D.new()
	area.name = "Contact_" + weapon_id
	area.position = local_pos
	area.collision_layer = 0
	area.collision_mask = 1
	area.monitoring = true
	area.set_meta("weapon_id", weapon_id)
	var asset_key := "components/weapons/wp-01" if weapon_id == "drill" else ("components/weapons/wp-02" if weapon_id == "saw" else "")
	if not asset_key.is_empty():
		area.set_meta("asset_key", asset_key)
		ArtAssets.mount_animation_visual(area, asset_key, Vector2(radius * 2.0, radius * 2.0))
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	cs.shape = circle
	area.add_child(cs)
	area.body_entered.connect(_on_weapon_body_entered.bind(weapon_id))
	if parent_override == null:
		core.add_child(area)
	else:
		parent_override.add_child(area)
	weapon_nodes[weapon_id] = area
	return area

func _build_weapons() -> void:
	front_weapon_mount = Node2D.new()
	front_weapon_mount.name = "FrontWeaponMount"
	front_weapon_mount.position = Vector2(drive_direction * 75.0, -2.0)
	core.add_child(front_weapon_mount)
	_make_sensor("drill", Vector2(drive_direction * 29.0, -3.0), 27, front_weapon_mount)
	_make_sensor("saw", Vector2(drive_direction * 18.0, 21.0), 30, front_weapon_mount)
	hammer_body = RigidBody2D.new()
	hammer_body.name = "PhysicalHammerHead"
	hammer_body.position = Vector2(drive_direction * 108, -31)
	hammer_body.mass = 1.35
	hammer_body.linear_damp = 0.4
	hammer_body.angular_damp = 0.22
	hammer_body.can_sleep = false
	hammer_body.collision_layer = 1
	hammer_body.collision_mask = 1
	hammer_body.set_meta("dir", drive_direction)
	hammer_body.set_meta("asset_key", "components/weapons/wp-03")
	hammer_body.set_script(HAMMER_SCRIPT)
	core.add_child(hammer_body)
	var hammer_shape := CollisionShape2D.new()
	var hammer_rect := RectangleShape2D.new()
	hammer_rect.size = Vector2(38, 20)
	hammer_shape.shape = hammer_rect
	hammer_body.add_child(hammer_shape)
	hammer_joint = _join(core, hammer_body, core.to_global(Vector2(drive_direction * 78, -29)), "HammerPivot")
	_make_sensor("hammer", Vector2.ZERO, 25, hammer_body)
	weapon_nodes["rocket_mount"] = Node2D.new()
	weapon_nodes["rocket_mount"].name = "RocketLauncherMount"
	weapon_nodes["rocket_mount"].position = Vector2(-drive_direction * 122.0, -40.0)
	front_weapon_mount.add_child(weapon_nodes["rocket_mount"])

func _physics_process(delta: float) -> void:
	elapsed += delta
	_flash = maxf(0.0, _flash - delta)
	if core == null or not is_instance_valid(core):
		return
	_update_audio_feedback()
	if not alive:
		return
	var sign_dir := drive_direction
	var siege_coasting := false
	if is_instance_valid(target):
		var delta_x := target.core.global_position.x - core.global_position.x
		if absf(delta_x) > 55.0:
			sign_dir = signf(delta_x)
		# Archetypes share the same force, damage and health rules; policies only change when they press.
		if not is_player and ai_archetype == "siegebreaker" and absf(delta_x) > 420.0 and not disabled["rocket"]:
			siege_coasting = fposmod(elapsed, 2.6) < 1.0
		elif not is_player and ai_archetype == "skirmisher" and booster_count > 0 and absf(delta_x) > 120.0:
			if absf(delta_x) < 165.0 and fposmod(elapsed, 3.4) < 0.9:
				sign_dir = -signf(delta_x)
		elif not is_player and ai_archetype == "spinner" and fposmod(elapsed, 2.8) < 0.35:
			sign_dir = -signf(delta_x)
	last_drive_input = sign_dir
	for i in wheels.size():
		var wid := "wheel_left" if i == 0 else "wheel_right"
		if not disabled[wid]:
			var grip_factor := 1.0
			var wheel_drive := 1.0
			var socket_id := "drive_left" if i == 0 else "drive_right"
			var mounted: Dictionary = build_config.get("parts", {}).get(socket_id, {})
			if not build_config.is_empty():
				var movement_id := str(mounted.get("id", "MV-01"))
				wheel_drive = float(GameState.PARTS.get(movement_id, {}).get("drive", 1.0))
				if movement_id == "MV-02": grip_factor = 1.28
			if not siege_coasting:
				wheels[i].apply_torque(sign_dir * drive_torque * grip_factor)
				if wheels[i].get_contact_count() > 0:
					var wheel_radius := 23.0 if chassis_id == "CH-02" else 27.0
					var traction_force := drive_torque / wheel_radius * 0.62 * wheel_drive * grip_factor
					core.apply_central_force(Vector2(sign_dir * traction_force, 0.0))
	if not disabled["crank_leg"]:
		crank_axle.apply_torque(sign_dir * crank_torque)
		crank_turn_total += absf(crank_axle.angular_velocity) * delta
	if booster_count > 0 and elapsed >= booster_timer and alive:
		var per_booster := Vector2(sign_dir * (150.0 / float(booster_count) + 55.0), -12.0 / float(booster_count))
		for booster_rotation in booster_rotations:
			core.apply_central_impulse(per_booster.rotated(booster_rotation + core.global_rotation))
		booster_timer = elapsed + 4.2
	if not disabled["hammer"]:
		# Alternating physical torque produces wind-up, strike, and recovery around a pinned pivot.
		hammer_body.apply_torque(sin(elapsed * 3.2) * 5200.0)
	for weapon_id in ["drill", "saw", "hammer"]:
		var area: Area2D = weapon_nodes[weapon_id]
		if is_instance_valid(area):
			if weapon_id != "hammer":
				area.rotation = elapsed * (12.0 if weapon_id == "drill" else -10.0)
				area.set_meta("live", not disabled[weapon_id])
				area.monitoring = not disabled[weapon_id]
			if not disabled[weapon_id] and area.monitoring:
				for overlapping_body in area.get_overlapping_bodies():
					_on_weapon_body_entered(overlapping_body, weapon_id)
	if not disabled["rocket"] and elapsed - float(last_fire["rocket"]) > 3.2:
		_fire_rocket(sign_dir)
		last_fire["rocket"] = elapsed
	queue_redraw()

func _fire_rocket(sign_dir: float) -> void:
	var p: RigidBody2D = PROJECTILE_SCENE.instantiate()
	p.source = self
	p.damage = 28.0 * (1.0 + 0.12 * float(_mounted_level("WP-04") - 1))
	get_parent().add_child(p)
	var mount: Node2D = weapon_nodes["rocket_mount"]
	var launch_direction := Vector2(sign_dir, 0.0).rotated(front_weapon_mount.global_rotation).normalized()
	last_rocket_direction = launch_direction
	p.global_position = mount.global_position + launch_direction * 22.0
	p.linear_velocity = core.linear_velocity + launch_direction * 430.0 + Vector2(0.0, -30.0).rotated(front_weapon_mount.global_rotation)
	BattleFX.rocket_muzzle(p.global_position - launch_direction * 7.0, launch_direction)
	launched_rockets += 1

func _on_weapon_body_entered(body: Node2D, weapon_id: String) -> void:
	if not alive or disabled.get(weapon_id, false) or (not body.is_in_group("machine_core") and not body.is_in_group("machine_components")):
		return
	var other: ScrapVehicle
	var target_component := ""
	if body.is_in_group("machine_components"):
		other = body.get_meta("owner") as ScrapVehicle
		target_component = str(body.get_meta("component_key", ""))
	else:
		other = body.get_parent() as ScrapVehicle
	if other == null or other == self or other.is_player == is_player:
		return
	var now := elapsed
	var rate := 0.18 if weapon_id in ["drill", "saw"] else 0.78
	if now - float(last_fire[weapon_id]) < rate:
		return
	last_fire[weapon_id] = now
	var dmg := 9.0 if weapon_id == "drill" else (11.0 if weapon_id == "saw" else 24.0)
	var weapon_part := "WP-01" if weapon_id == "drill" else ("WP-02" if weapon_id == "saw" else "WP-03")
	if weapon_id == "rocket": weapon_part = "WP-04"
	dmg *= 1.0 + 0.12 * float(_mounted_level(weapon_part) - 1)
	if target_component == "":
		target_component = other._nearest_armor(global_position)
	if target_component == "":
		target_component = "wheel_left" if weapon_id in ["drill", "saw"] else "hammer"
	other.take_hit(dmg, target_component, weapon_id, sign_dir_to(other))
	attack_hits_landed += 1
	if weapon_id == "hammer":
		other.core.apply_central_impulse(Vector2(sign_dir_to(other) * 155.0, -38.0))

func sign_dir_to(other: ScrapVehicle) -> float:
	return signf(other.core.global_position.x - core.global_position.x)

func _mounted_level(component_id: String) -> int:
	if build_config.is_empty(): return 1
	for item in build_config.get("parts", {}).values():
		if str(item.get("id", "")) == component_id:
			return GameState.component_level(item, component_id)
	return 1

func _nearest_armor(world_position: Vector2) -> String:
	var closest := ""
	var min_distance := 92.0
	for armor_key in armor_nodes:
		var body: RigidBody2D = armor_nodes[armor_key]
		if is_instance_valid(body) and not disabled.get(armor_key, false):
			var dist := body.global_position.distance_to(world_position)
			if dist < min_distance:
				min_distance = dist
				closest = str(armor_key)
	return closest

func take_hit(amount: float, part: String, source_weapon: String, direction: float) -> void:
	if not alive:
		return
	raw_damage_received += amount
	var armor_active: bool = (part == "armor" and not disabled.get("armor", true)) or (part.begins_with("armor_") and not disabled.get(part, true))
	comp_hp[part] = maxf(0.0, float(comp_hp.get(part, component_health)) - amount)
	health = maxf(0.0, health - amount * (0.35 if armor_active else 0.55))
	_flash = 0.22
	core.apply_central_impulse(Vector2(direction * amount * 1.35, -amount * 0.28))
	BattleFX.weapon_impact(_component_world_position(part), source_weapon, amount, Vector2(direction, -0.18).normalized())
	if float(comp_hp[part]) <= 0.0 and not disabled[part]:
		disabled[part] = true
		BattleFX.component_break(_component_world_position(part))
		component_disabled.emit(self, part)
		if part.begins_with("wheel"):
			if part == "wheel_left":
				wheels[0].set_deferred("freeze", true)
				wheel_joints[0].queue_free()
			else:
				wheels[1].set_deferred("freeze", true)
				wheel_joints[1].queue_free()
		elif part == "crank_leg":
			crank_axle.set_deferred("freeze", true)
			crank_leg.set_deferred("freeze", true)
			crank_axle_joint.queue_free()
			crank_leg_joint.queue_free()
		elif part in ["drill", "saw", "hammer"]:
			if is_instance_valid(weapon_nodes.get(part)):
				weapon_nodes[part].set_deferred("monitoring", false)
			if part == "hammer":
				hammer_body.set_deferred("freeze", true)
				hammer_body.set_deferred("collision_layer", 0)
				hammer_body.set_deferred("collision_mask", 0)
				hammer_body.visible = false
				hammer_joint.queue_free()
		elif part.begins_with("armor_"):
			var armor_body: RigidBody2D = armor_nodes.get(part)
			if is_instance_valid(armor_body):
				armor_body.set_meta("wrecked", true)
				armor_body.set_deferred("collision_layer", 0)
				armor_body.set_deferred("collision_mask", 0)
			var any_armor_active := false
			for armor_key in armor_nodes:
				if not disabled.get(str(armor_key), true): any_armor_active = true
			disabled["armor"] = not any_armor_active
		elif part == "shock_absorber":
			core.angular_damp = 1.15
			if is_instance_valid(shock_absorber_body):
				shock_absorber_body.set_deferred("collision_layer", 0)
		elif part == "counterweight" and is_instance_valid(counterweight_body):
			counterweight_body.set_deferred("collision_layer", 0)
	if health <= 0.0:
		alive = false
		stop_effect_audio()
		BattleFX.rocket_explosion(core.global_position, 1.15)
		core_destroyed.emit(self)
		core.apply_central_impulse(Vector2(direction * 260.0, -130.0))

func apply_projectile_hit(amount: float, direction: float) -> void:
	take_hit(amount, "rocket", "rocket", direction)
	# Splash damage is deliberately applied to the local chassis health, not an invisible global armor multiplier.

func total_component_health() -> float:
	var total := 0.0
	for value in comp_hp.values(): total += float(value)
	return total

func _draw_asset_at_vehicle_point(asset_key: String, local_point: Vector2, local_angle: float, image_size: Vector2) -> bool:
	var center := core.position + local_point.rotated(core.rotation)
	draw_set_transform(center, core.rotation + local_angle, Vector2.ONE)
	var drawn := ArtAssets.draw_texture(self, asset_key, Rect2(-image_size * 0.5, image_size))
	draw_set_transform(core.position, core.rotation, Vector2.ONE)
	return drawn

func _draw() -> void:
	# Original procedural development-machine silhouette and mounts.
	if core == null or not is_instance_valid(core): return
	draw_set_transform(core.position, core.rotation, Vector2.ONE)
	var color := Color("59666a") if _flash <= 0.0 else Color("fff0bc")
	var sign_dir := drive_direction
	var body_rect := Rect2(Vector2(-72, -28), Vector2(144, 56))
	if chassis_id == "CH-02":
		body_rect = Rect2(Vector2(-75, -22), Vector2(150, 44))
	elif chassis_id == "CH-03":
		body_rect = Rect2(Vector2(-83, -36), Vector2(166, 72))
	var chassis_key := "machines/chassis/" + chassis_id.to_lower()
	var has_chassis_texture := false
	if not _chassis_animation_active:
		var chassis_modulate := Color("fff0bc") if _flash > 0.0 else Color.WHITE
		has_chassis_texture = ArtAssets.draw_texture(self, chassis_key, body_rect, chassis_modulate)
	if not _chassis_animation_active and not has_chassis_texture:
		draw_rect(body_rect, color, true)
		draw_rect(body_rect, Color("182126"), false, 4.0)
		draw_rect(Rect2(Vector2(-34, -19), Vector2(64, 14)), Color("a78a4c"), true)
		draw_rect(Rect2(Vector2(-18, -17), Vector2(30, 9)), Color("d4c18d"), true)
		# Original procedural nose plate and rivets remain the no-art fallback.
		var nose := PackedVector2Array([Vector2(sign_dir * 69, -26), Vector2(sign_dir * 91, -15), Vector2(sign_dir * 82, 4), Vector2(sign_dir * 69, 12)])
		draw_colored_polygon(nose, Color("b66c35") if not disabled["armor"] else Color("393f40"))
		for x in [-55.0, -28.0, 30.0, 57.0]:
			draw_circle(Vector2(x, -18), 3.2, Color("e7bd67"))
	# Weapon marks: turning heads are drawn separately within their sensor Areas.
	if not disabled["drill"]:
		var pos := _front_point(Vector2(sign_dir * 103.0, -5.0))
		var drill_animated := is_instance_valid(weapon_nodes.get("drill")) and bool(weapon_nodes["drill"].get_meta("external_animation_enabled", false))
		if not drill_animated and not _draw_asset_at_vehicle_point("components/weapons/wp-01", pos, front_weapon_rotation + elapsed * 12.0, Vector2(34.0, 34.0)):
			draw_circle(pos, 15.0, Color("86938e"))
			draw_circle(pos, 8.0, Color("d9a34f"))
			for j in 4:
				var a := front_weapon_rotation + elapsed * 12.0 + TAU * float(j) / 4.0
				draw_line(pos, pos + Vector2(cos(a), sin(a)) * 15.0, Color("e6c66c"), 2.4)
	if not disabled["saw"]:
		var pos2 := _front_point(Vector2(sign_dir * 88.0, 20.0))
		var saw_animated := is_instance_valid(weapon_nodes.get("saw")) and bool(weapon_nodes["saw"].get_meta("external_animation_enabled", false))
		if not saw_animated and not _draw_asset_at_vehicle_point("components/weapons/wp-02", pos2, front_weapon_rotation + elapsed * -10.0, Vector2(40.0, 40.0)):
			draw_circle(pos2, 16, Color("a7afb0"))
			for j in 8:
				var a2 := front_weapon_rotation + elapsed * -10.0 + TAU * float(j) / 8.0
				draw_line(pos2 + Vector2(cos(a2), sin(a2)) * 9, pos2 + Vector2(cos(a2), sin(a2)) * 17, Color("f1cc73"), 2.4)
	if not disabled["hammer"]:
		var base := _front_point(Vector2(sign_dir * 77.0, -29.0))
		draw_circle(base, 9.0, Color("d69a46"))
		draw_circle(base, 3.0, Color("20282a"))
	if not disabled["rocket"]:
		var rpos := _front_point(Vector2(-sign_dir * 42.0, -43.0))
		if not _draw_asset_at_vehicle_point("components/weapons/wp-04", rpos, front_weapon_rotation, Vector2(48.0, 24.0)):
			var rocket_shape := PackedVector2Array()
			for corner in [Vector2(-21,-7),Vector2(21,-7),Vector2(21,7),Vector2(-21,7)]: rocket_shape.append(rpos + corner.rotated(front_weapon_rotation))
			draw_colored_polygon(rocket_shape, Color("78969a"))
			var barrel_shape := PackedVector2Array()
			for corner in [Vector2(-14,-4),Vector2(8,-4),Vector2(8,4),Vector2(-14,4)]: barrel_shape.append(rpos + corner.rotated(front_weapon_rotation))
			draw_colored_polygon(barrel_shape, Color("b4c0b9"))
	if disabled["armor"]:
		draw_line(Vector2(sign_dir * 60, -20), Vector2(sign_dir * 83, 12), Color("3c4140"), 5.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
