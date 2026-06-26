extends CharacterBody2D

signal stats_changed(stats: Dictionary)
signal status_changed(status_text: String)
signal attack_landed(target: Node, damage: int)
signal interaction_changed(label: String)
signal interaction_requested(target: Node)
signal knocked_out

@export var base_speed := 285.0
@export var play_area := Rect2(24, 72, 912, 420)
@export var max_health := 100
@export var max_stamina := 100.0
@export var base_damage := 16
@export var attack_range := 48.0
@export var attack_cooldown := 0.28
@export var dash_speed := 760.0
@export var dash_cost := 28.0
@export var dash_time := 0.11

@onready var attack_area: Area2D = $AttackArea
@onready var interaction_area: Area2D = $InteractionArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var body: Polygon2D = $Body
@onready var attack_arc: Polygon2D = $AttackArea/Arc
@onready var camera: Camera2D = $Camera2D

var health := max_health
var stamina := max_stamina
var grit := 0
var supplies := 0
var last_direction := Vector2.RIGHT
var _attack_timer := 0.0
var _attack_active_timer := 0.0
var _dash_timer := 0.0
var _invulnerable_timer := 0.0
var _hit_targets: Array[Node] = []
var _nearby_interactables: Array[Node] = []
var _nearest_interactable: Node = null
var _statuses := {}
var _status_tick_timer := 0.0

func _ready() -> void:
	camera.make_current()
	attack_area.body_entered.connect(_on_attack_body_entered)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	attack_area.monitoring = false
	attack_shape.disabled = true
	attack_arc.visible = false
	_emit_all_stats()

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_statuses(delta)
	_handle_actions()
	_move_player(delta)
	_regenerate_stamina(delta)
	_emit_all_stats()

func reset_to(start_position: Vector2) -> void:
	position = start_position
	velocity = Vector2.ZERO
	health = max_health
	stamina = max_stamina
	grit = 0
	supplies = 0
	_statuses.clear()
	_attack_timer = 0.0
	_attack_active_timer = 0.0
	_dash_timer = 0.0
	_invulnerable_timer = 0.0
	_hit_targets.clear()
	_nearby_interactables.clear()
	_set_nearest_interactable(null)
	attack_area.monitoring = false
	attack_shape.disabled = true
	attack_arc.visible = false
	_emit_all_stats()

func add_supply(amount: int = 1) -> void:
	supplies += amount
	stamina = min(max_stamina, stamina + 12.0)
	grit += 1
	_emit_all_stats()

func recover_between_phases(health_amount: int, stamina_amount: float) -> void:
	heal(health_amount)
	stamina = min(max_stamina, stamina + stamina_amount)
	_emit_all_stats()

func apply_item(item_data: Dictionary) -> void:
	match item_data.get("kind", "scrap"):
		"fet_d":
			heal(12)
			clear_status("withdrawal")
			apply_status("well", 18.0, 1.0)
		"food":
			heal(8)
			stamina = min(max_stamina, stamina + 22.0)
		"weapon":
			apply_status("armed", 18.0, 1.0)
			grit += 2
		"gear":
			stamina = min(max_stamina, stamina + 14.0)
			grit += 1
		"bandage":
			heal(24)
		"coffee":
			apply_status("insomnia", 10.0, 1.0)
			stamina = min(max_stamina, stamina + 35.0)
		"street_meds":
			apply_status("withdrawal", 14.0, 1.0)
			heal(45)
		"broken_bottle":
			apply_status("armed", 12.0, 1.0)
		_:
			add_supply(1)
	_emit_all_stats()

func apply_status(status_name: String, duration: float, intensity: float = 1.0) -> void:
	_statuses[status_name] = {
		"duration": max(duration, _statuses.get(status_name, {}).get("duration", 0.0)),
		"intensity": intensity,
	}
	_emit_status_text()

func clear_status(status_name: String) -> void:
	if _statuses.has(status_name):
		_statuses.erase(status_name)
		_emit_status_text()

func take_damage(amount: int, source: Node2D = null) -> void:
	if _invulnerable_timer > 0.0 or health <= 0:
		return
	var final_amount := amount
	if _statuses.has("psychosis"):
		final_amount = int(ceil(final_amount * 1.15))
	health = max(0, health - final_amount)
	grit += 2
	_invulnerable_timer = 0.45
	_apply_hit_flash()
	if source != null:
		var shove := (global_position - source.global_position).normalized()
		velocity += shove * 240.0
	if health <= 0:
		knocked_out.emit()
	_emit_all_stats()

func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	_emit_all_stats()

func get_attack_damage() -> int:
	var damage := base_damage + int(grit * 0.35)
	if _statuses.has("armed"):
		damage += 10
	if _statuses.has("insomnia"):
		damage += 3
	if _statuses.has("withdrawal") and not _statuses.has("well"):
		damage = int(floor(damage * 0.82))
	if _statuses.has("psychosis"):
		damage += 6
	return max(1, damage)

func _handle_actions() -> void:
	_update_nearest_interactable()
	if Input.is_action_just_pressed("attack"):
		if _nearest_interactable != null:
			interaction_requested.emit(_nearest_interactable)
		else:
			_try_attack()
	if Input.is_action_just_pressed("dash"):
		_try_dash()

func _move_player(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction.length() > 0.05:
		last_direction = direction.normalized()
	if _statuses.has("psychosis") and direction != Vector2.ZERO:
		direction = direction.rotated(sin(Time.get_ticks_msec() * 0.014) * 0.32)
	var speed := base_speed * _speed_multiplier()
	if _dash_timer > 0.0:
		velocity = last_direction * dash_speed
	else:
		velocity = direction * speed
	move_and_slide()
	position = position.clamp(play_area.position, play_area.position + play_area.size)
	if _attack_active_timer <= 0.0:
		_update_attack_area_transform()

func clear_interactable(target: Node) -> void:
	_nearby_interactables.erase(target)
	if _nearest_interactable == target:
		_set_nearest_interactable(null)
	_update_nearest_interactable()

func _on_interaction_area_entered(area: Area2D) -> void:
	if _is_interactable(area) and not _nearby_interactables.has(area):
		_nearby_interactables.append(area)
		_update_nearest_interactable()

func _on_interaction_area_exited(area: Area2D) -> void:
	_nearby_interactables.erase(area)
	if _nearest_interactable == area:
		_set_nearest_interactable(null)
	_update_nearest_interactable()

func _update_nearest_interactable() -> void:
	var best: Node = null
	var best_distance := INF
	for candidate in _nearby_interactables.duplicate():
		if not is_instance_valid(candidate) or not _is_interactable(candidate):
			_nearby_interactables.erase(candidate)
			continue
		var distance := global_position.distance_squared_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	_set_nearest_interactable(best)

func _set_nearest_interactable(target: Node) -> void:
	if _nearest_interactable == target:
		return
	_nearest_interactable = target
	var label := ""
	if _nearest_interactable != null:
		label = _interaction_label(_nearest_interactable)
	interaction_changed.emit(label)

func _is_interactable(node: Node) -> bool:
	return node != null and (node.has_method("interact") or node.has_meta("interaction_label"))

func _interaction_label(node: Node) -> String:
	if node.has_method("get_interaction_label"):
		return str(node.get_interaction_label())
	return str(node.get_meta("interaction_label", "Interact"))

func _try_attack() -> void:
	if _attack_timer > 0.0 or stamina < 10.0 or health <= 0:
		return
	stamina -= 10.0
	_attack_timer = attack_cooldown * _attack_speed_multiplier()
	_attack_active_timer = 0.09
	_hit_targets.clear()
	_update_attack_area_transform()
	attack_shape.disabled = false
	attack_arc.visible = true
	attack_area.monitoring = true
	call_deferred("_hit_current_attack_overlaps")

func _try_dash() -> void:
	if _dash_timer > 0.0 or stamina < dash_cost or health <= 0:
		return
	stamina -= dash_cost
	_dash_timer = dash_time
	_invulnerable_timer = max(_invulnerable_timer, dash_time + 0.08)

func _update_attack_area_transform() -> void:
	attack_area.position = last_direction.normalized() * attack_range
	attack_area.rotation = last_direction.angle()

func _hit_current_attack_overlaps() -> void:
	if _attack_active_timer <= 0.0:
		return
	for body_node in attack_area.get_overlapping_bodies():
		_on_attack_body_entered(body_node)

func _on_attack_body_entered(body_node: Node) -> void:
	if _attack_active_timer <= 0.0 or body_node == self or _hit_targets.has(body_node):
		return
	if body_node.has_method("take_hit"):
		_hit_targets.append(body_node)
		body_node.take_hit(get_attack_damage(), last_direction, self)
		grit += 1
		attack_landed.emit(body_node, get_attack_damage())

func _update_timers(delta: float) -> void:
	_attack_timer = max(0.0, _attack_timer - delta)
	_dash_timer = max(0.0, _dash_timer - delta)
	_invulnerable_timer = max(0.0, _invulnerable_timer - delta)
	if _attack_active_timer > 0.0:
		_attack_active_timer -= delta
		if _attack_active_timer <= 0.0:
			attack_area.monitoring = false
			attack_shape.disabled = true
			attack_arc.visible = false

func _update_statuses(delta: float) -> void:
	var changed := false
	for status_name in _statuses.keys():
		_statuses[status_name]["duration"] -= delta
		if _statuses[status_name]["duration"] <= 0.0:
			_statuses.erase(status_name)
			changed = true
	_status_tick_timer -= delta
	if _status_tick_timer <= 0.0:
		_status_tick_timer = 1.0
		if _statuses.has("withdrawal") and not _statuses.has("well"):
			take_damage(1)
		if _statuses.has("psychosis"):
			stamina = max(0.0, stamina - 2.0)
	if changed:
		_emit_status_text()

func _regenerate_stamina(delta: float) -> void:
	var regen := 18.0
	if _statuses.has("withdrawal") and not _statuses.has("well"):
		regen *= 0.45
	if _statuses.has("insomnia"):
		regen *= 1.45
	stamina = min(max_stamina, stamina + regen * delta)

func _speed_multiplier() -> float:
	var multiplier := 1.0
	if _statuses.has("withdrawal") and not _statuses.has("well"):
		multiplier -= 0.18
	if _statuses.has("insomnia"):
		multiplier += 0.16
	if _statuses.has("psychosis"):
		multiplier += 0.08
	return max(0.45, multiplier)

func _attack_speed_multiplier() -> float:
	var multiplier := 1.0
	if _statuses.has("insomnia"):
		multiplier *= 0.78
	if _statuses.has("withdrawal") and not _statuses.has("well"):
		multiplier *= 1.22
	return multiplier

func _emit_all_stats() -> void:
	stats_changed.emit({
		"health": health,
		"max_health": max_health,
		"stamina": int(round(stamina)),
		"max_stamina": int(max_stamina),
		"grit": grit,
		"supplies": supplies,
		"damage": get_attack_damage(),
	})
	_emit_status_text()

func _emit_status_text() -> void:
	if _statuses.is_empty():
		status_changed.emit("Status: steady")
		return
	var parts: Array[String] = []
	for status_name in _statuses.keys():
		parts.append("%s %.0fs" % [status_name.capitalize(), _statuses[status_name]["duration"]])
	status_changed.emit("Status: " + ", ".join(parts))

func _apply_hit_flash() -> void:
	body.color = Color(1.0, 0.36, 0.36, 1.0)
	await get_tree().create_timer(0.08).timeout
	body.color = Color(0.376471, 0.647059, 0.980392, 1.0)
