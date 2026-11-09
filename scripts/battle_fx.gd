extends Node

var _particle_texture: Texture2D
var _metal_impact: AudioStream
var _rocket_launch: AudioStream
var _scrap_blast: AudioStream
var counters := {"impact_events": 0, "rocket_launches": 0, "explosions": 0, "component_breaks": 0, "particle_emitters_created": 0, "one_shot_audio_started": 0}

func _ready() -> void:
	_particle_texture = _make_particle_texture()
	_metal_impact = load("res://assets/audio/metal_impact.mp3") as AudioStream
	_rocket_launch = load("res://assets/audio/rocket_launch.mp3") as AudioStream
	_scrap_blast = load("res://assets/audio/scrap_blast.mp3") as AudioStream

func _make_particle_texture() -> Texture2D:
	var image := Image.create(20, 20, false, Image.FORMAT_RGBA8)
	for y in 20:
		for x in 20:
			var radius := Vector2(float(x) - 9.5, float(y) - 9.5).length() / 9.5
			var alpha := 1.0 - smoothstep(0.15, 1.0, radius)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)

func _current_scene() -> Node:
	var scene := get_tree().current_scene
	return scene if scene != null else get_tree().root

func _volume_db(multiplier: float) -> float:
	var linear := clampf(float(GameState.sfx_volume) * multiplier, 0.0, 1.0)
	return linear_to_db(maxf(linear, 0.0001))

func _play_at(stream: AudioStream, position: Vector2, volume: float, pitch: float = 1.0) -> void:
	if stream == null or GameState.sfx_volume <= 0.001:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.global_position = position
	player.volume_db = _volume_db(volume)
	player.pitch_scale = pitch
	player.max_distance = 1800.0
	player.attenuation = 0.55
	player.finished.connect(player.queue_free)
	player.add_to_group("battle_effect_audio")
	_current_scene().add_child(player)
	player.global_position = position
	player.play()
	counters.one_shot_audio_started = int(counters.one_shot_audio_started) + 1

func _configure_particle(particles: CPUParticles2D, color: Color, direction: Vector2, spread_degrees: float, velocity_min: float, velocity_max: float, gravity: Vector2, scale_min: float, scale_max: float, damping: float = 0.0) -> void:
	particles.color = color
	particles.direction = direction.normalized() if direction.length_squared() > 0.001 else Vector2(0.0, -1.0)
	particles.spread = spread_degrees
	particles.initial_velocity_min = velocity_min
	particles.initial_velocity_max = velocity_max
	particles.gravity = gravity
	particles.scale_amount_min = scale_min
	particles.scale_amount_max = scale_max
	particles.damping_min = damping
	particles.damping_max = damping * 1.45
	particles.angle_min = -180.0
	particles.angle_max = 180.0
	particles.angular_velocity_min = -270.0
	particles.angular_velocity_max = 270.0

func _burst(position: Vector2, tint: Color, count: int, lifetime: float, velocity_min: float, velocity_max: float, direction: Vector2, spread: float, scale_min: float, scale_max: float, gravity: Vector2, damping: float = 0.0) -> CPUParticles2D:
	var particles := CPUParticles2D.new()
	particles.name = "ProceduralBurst"
	particles.global_position = position
	particles.one_shot = true
	particles.amount = count
	particles.lifetime = lifetime
	particles.explosiveness = 0.88
	particles.randomness = 0.72
	particles.texture = _particle_texture
	_configure_particle(particles, tint, direction, spread, velocity_min, velocity_max, gravity, scale_min, scale_max, damping)
	particles.z_index = 20
	particles.add_to_group("battle_effect_particles")
	particles.finished.connect(particles.queue_free)
	_current_scene().add_child(particles)
	particles.global_position = position
	particles.emitting = true
	counters.particle_emitters_created = int(counters.particle_emitters_created) + 1
	return particles

func weapon_impact(position: Vector2, weapon_id: String, strength: float, hit_direction: Vector2) -> void:
	counters.impact_events = int(counters.impact_events) + 1
	var scale := clampf(strength / 24.0, 0.55, 1.5)
	var tint := Color("ffd477") if weapon_id == "hammer" else Color("f4b554")
	_burst(position, tint, int(10.0 * scale) + 6, 0.38, 90.0 * scale, 290.0 * scale, hit_direction, 150.0, 0.6, 1.5, Vector2(0.0, 190.0), 28.0)
	_burst(position, Color(0.30, 0.34, 0.34, 0.55), 8, 0.50, 18.0, 70.0, Vector2(0.0, -1.0), 42.0, 0.8, 1.7, Vector2(0.0, -45.0), 18.0)
	var volume := 0.62 if weapon_id in ["drill", "saw"] else 0.92
	_play_at(_metal_impact, position, volume, randf_range(0.88, 1.12))

func rocket_muzzle(position: Vector2, direction: Vector2) -> void:
	counters.rocket_launches = int(counters.rocket_launches) + 1
	_burst(position, Color("ff9e46"), 12, 0.23, 35.0, 130.0, -direction, 58.0, 0.55, 1.1, Vector2(0.0, 110.0), 30.0)
	_play_at(_rocket_launch, position, 0.8, randf_range(0.94, 1.06))

func rocket_explosion(position: Vector2, strength: float = 1.0) -> void:
	counters.explosions = int(counters.explosions) + 1
	var scale := clampf(strength, 0.75, 1.5)
	_burst(position, Color("ffb14a"), int(28.0 * scale), 0.52, 100.0, 390.0 * scale, Vector2(0.0, -1.0), 180.0, 0.8, 2.4, Vector2(0.0, 145.0), 24.0)
	_burst(position, Color(0.23, 0.27, 0.29, 0.72), 20, 0.9, 28.0, 105.0, Vector2(0.0, -1.0), 62.0, 1.0, 2.8, Vector2(0.0, -38.0), 10.0)
	_play_at(_scrap_blast, position, 1.0, randf_range(0.92, 1.08))

func component_break(position: Vector2) -> void:
	counters.component_breaks = int(counters.component_breaks) + 1
	_burst(position, Color("ffcc6b"), 18, 0.55, 90.0, 280.0, Vector2(0.0, -1.0), 180.0, 0.6, 1.8, Vector2(0.0, 210.0), 22.0)
	_burst(position, Color(0.25, 0.29, 0.31, 0.7), 16, 0.85, 20.0, 74.0, Vector2(0.0, -1.0), 50.0, 0.9, 2.4, Vector2(0.0, -42.0), 12.0)
	_play_at(_metal_impact, position, 0.78, randf_range(0.68, 0.84))

func attach_rocket_trail(parent: Node2D) -> CPUParticles2D:
	var trail := CPUParticles2D.new()
	trail.name = "RocketExhaustParticles"
	trail.position = Vector2(-17.0, 0.0)
	trail.one_shot = false
	trail.amount = 14
	trail.lifetime = 0.34
	trail.explosiveness = 0.0
	trail.randomness = 0.4
	trail.texture = _particle_texture
	_configure_particle(trail, Color(1.0, 0.48, 0.16, 0.7), Vector2(-1.0, 0.0), 24.0, 12.0, 52.0, Vector2(0.0, 0.0), 0.45, 1.15, 24.0)
	trail.z_index = -1
	trail.add_to_group("battle_effect_particles")
	parent.add_child(trail)
	trail.emitting = true
	counters.particle_emitters_created = int(counters.particle_emitters_created) + 1
	return trail

func create_engine_exhaust(parent: Node2D, local_position: Vector2, backward_direction: float) -> CPUParticles2D:
	var exhaust := CPUParticles2D.new()
	exhaust.name = "EngineExhaustParticles"
	exhaust.position = local_position
	exhaust.one_shot = false
	exhaust.amount = 10
	exhaust.lifetime = 0.42
	exhaust.explosiveness = 0.0
	exhaust.randomness = 0.62
	exhaust.texture = _particle_texture
	_configure_particle(exhaust, Color(1.0, 0.52, 0.2, 0.48), Vector2(backward_direction, -0.08), 24.0, 9.0, 36.0, Vector2(0.0, -10.0), 0.35, 0.95, 16.0)
	exhaust.z_index = -1
	exhaust.add_to_group("battle_effect_particles")
	parent.add_child(exhaust)
	exhaust.emitting = true
	counters.particle_emitters_created = int(counters.particle_emitters_created) + 1
	return exhaust

func metrics_snapshot() -> Dictionary:
	var result: Dictionary = counters.duplicate(true)
	result["active_particle_emitters"] = get_tree().get_nodes_in_group("battle_effect_particles").size()
	result["active_one_shot_audio"] = get_tree().get_nodes_in_group("battle_effect_audio").size()
	result["all_sfx_assets_loaded"] = _metal_impact != null and _rocket_launch != null and _scrap_blast != null
	return result

func dispose_transient_effects() -> void:
	for node in get_tree().get_nodes_in_group("battle_effect_particles"):
		if node is CPUParticles2D:
			node.emitting = false
			node.queue_free()
	for node in get_tree().get_nodes_in_group("battle_effect_audio"):
		if node is AudioStreamPlayer2D:
			node.stop()
			node.stream = null
			node.queue_free()
	_particle_texture = null
	_metal_impact = null
	_rocket_launch = null
	_scrap_blast = null
