extends RigidBody2D

var source: ScrapVehicle
var damage := 28.0
var age := 0.0
var exploded := false

func _ready() -> void:
	gravity_scale = 0.0
	mass = 0.22
	linear_damp = 0.0
	collision_layer = 1
	collision_mask = 1
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	BattleFX.attach_rocket_trail(self)

func _physics_process(delta: float) -> void:
	age += delta
	rotation = linear_velocity.angle()
	if age > 4.5:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if exploded or body == source or (source != null and body == source.core):
		return
	var v: ScrapVehicle
	var target_part := "rocket"
	if body.is_in_group("machine_components"):
		v = body.get_meta("owner") as ScrapVehicle
		target_part = str(body.get_meta("component_key", "rocket"))
	elif body.is_in_group("machine_core"):
		v = body.get_parent() as ScrapVehicle
	if v != null:
		if source == null or v.is_player == source.is_player:
			return
		v.take_hit(damage, target_part, "rocket", signf(linear_velocity.x))
		for candidate in get_tree().get_nodes_in_group("vehicles"):
			if candidate is ScrapVehicle and candidate != v and candidate.is_player != source.is_player:
				if candidate.core.global_position.distance_to(global_position) < 92.0:
					var blast_part: String = candidate._nearest_armor(global_position)
					if blast_part == "": blast_part = "wheel_left"
					candidate.take_hit(damage * 0.35, blast_part, "rocket_splash", signf(linear_velocity.x))
		_explode()
	elif body is StaticBody2D or body is RigidBody2D:
		_explode()

func _explode() -> void:
	if exploded:
		return
	exploded = true
	BattleFX.rocket_explosion(global_position, clampf(damage / 28.0, 0.75, 1.5))
	set_deferred("freeze", true)
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	var tween := create_tween()
	tween.tween_method(func(r: float): set_meta("blast_radius", r); queue_redraw(), 5.0, 64.0, 0.18)
	tween.tween_callback(queue_free)

func _draw() -> void:
	if exploded:
		var radius := float(get_meta("blast_radius", 18.0))
		draw_circle(Vector2.ZERO, radius, Color(1.0, 0.47, 0.12, 0.24))
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color("ffb952"), 4.0)
		return
	draw_colored_polygon(PackedVector2Array([Vector2(-16,-5),Vector2(10,-5),Vector2(18,0),Vector2(10,5),Vector2(-16,5)]), Color("d5d5c2"))
	draw_circle(Vector2(-17,0), 4.0, Color("ff7b35"))
	draw_circle(Vector2(-24,0), 2.4, Color("ffd26a"))
