extends CharacterBody2D

signal stats_changed(stats: Dictionary)
signal status_changed(status_text: String)
signal attack_landed(target: Node, damage: int)
signal interaction_changed(label: String)
signal interaction_requested(target: Node)
signal knocked_out

@export var base_speed := 285.0
# Default expanded bounds; will be overridden at runtime if the current scene has a PlayArea node.
@export var play_area := Rect2(-1200, -900, 2400, 1800)
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
	# Use print (not print_debug) so output appears in web builds and the editor console.
	print("Player._ready start: path=", get_path(), " position=", position, " play_area=", play_area)
	# Ensure visible for debugging
	body.visible = true
	camera.make_current()
	# Try to bind play_area from the current scene's PlayArea node if present.
	_bind_play_area()
	print("Player._ready after bind: play_area=", play_area, " camera_current=", camera.is_current(), " camera_zoom=", camera.zoom)
	attack_area.body_entered.connect(_on_attack_body_entered)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	attack_area.monitoring = false
	attack_shape.disabled = true
	attack_arc.visible = false
	_emit_all_stats()
	# Update camera limits based on play_area
	_update_camera_limits()

func _bind_play_area() -> void:
	# Get the active scene (the one you opened in the editor/run-time)
	var scene := get_tree().get_current_scene()
	if scene == null:
		print("Player._bind_play_area: no current_scene")
		return
	# Look for a node named PlayArea under the current scene
	var pa := scene.get_node_or_null("PlayArea")
	if pa == null:
		print("Player._bind_play_area: no PlayArea node found")
		return
	# Try to read offset_left/top/right/bottom properties (used in scenes/main.tscn)
	var left := null
	var top := null
	var right := null
	var bottom := null
	# Use get() defensively
	if pa.has_method("get"):
		left = pa.get("offset_left")
		top = pa.get("offset_top")
		right = pa.get("offset_right")
		bottom = pa.get("offset_bottom")

	# If any are null/invalid, try other ways to read bounds
	if left == null or top == null or right == null or bottom == null:
		# Try get_rect() if it's a Control-derived node
		if pa.has_method("get_rect"):
			var r = pa.get_rect()
			play_area = Rect2(r.position, r.size)
			print("Player._bind_play_area: bound from get_rect(): ", play_area)
			return
		# Try position/size properties
		if pa.has_method("get_position") and pa.has_method("get_size"):
			var p = pa.get_position()
			var s = pa.get_size()
			play_area = Rect2(p, s)
			print("Player._bind_play_area: bound from position/size: ", play_area)
			return
		# Nothing worked — leave default and log
		print("Player._bind_play_area: could not read PlayArea offsets; using default: ", play_area)
		return

	# Compute Rect2 from offsets (cast to float defensively)
	var pos := Vector2(float(left), float(top))
	var size := Vector2(float(right) - float(left), float(bottom) - float(top))
	play_area = Rect2(pos, size)
	print("Player._bind_play_area: bound from offsets: ", play_area)

func _update_camera_limits() -> void:
	# Set camera limits to the play_area bounds so the camera doesn't scroll beyond the playable area
	camera.limit_left = int(play_area.position.x)
	camera.limit_top = int(play_area.position.y)
	camera.limit_right = int(play_area.position.x + play_area.size.x)
	camera.limit_bottom = int(play_area.position.y + play_area.size.y)
	print("Camera limits updated to: left=%d, top=%d, right=%d, bottom=%d" % [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom])

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_statuses(delta)
	_handle_actions()
	_move_player(delta)
	_regenerate_stamina(delta)
	_emit_all_stats()

func _handle_actions() -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction.normalized() * base_speed
	
	if input_direction != Vector2.ZERO:
		last_direction = input_direction
	
	if Input.is_action_just_pressed("attack"):
		_perform_attack()
	
	if Input.is_action_just_pressed("dash") and _dash_timer <= 0.0:
		_perform_dash()
	
	if Input.is_action_just_pressed("interact"):
		if _nearest_interactable:
			interaction_requested.emit(_nearest_interactable)

func _move_player(delta: float) -> void:
	move_and_slide()
	# Clamp position to play_area (with buffer for player collision shape)
	var buffer := 17.0  # Half of player body size
	var clamped_pos = position.clamp(play_area.position + Vector2(buffer, buffer), play_area.position + play_area.size - Vector2(buffer, buffer))
	position = clamped_pos

func _perform_attack() -> void:
	if _attack_timer > 0.0:
		return
	
	_attack_timer = attack_cooldown
	_attack_active_timer = 0.08
	attack_shape.disabled = false
	attack_arc.visible = true
	_hit_targets.clear()
	
	# Rotate attack area to face direction
	var angle = last_direction.angle()
	attack_area.rotation = angle

func _perform_dash() -> void:
	if stamina < dash_cost:
		return
	
	stamina -= dash_cost
	_dash_timer = dash_time
	velocity = last_direction.normalized() * dash_speed

func _update_timers(delta: float) -> void:
	_attack_timer -= delta
	_attack_active_timer -= delta
	_dash_timer -= delta
	_invulnerable_timer -= delta
	
	if _attack_active_timer <= 0.0 and attack_shape.disabled == false:
		attack_shape.disabled = true
		attack_arc.visible = false

func _regenerate_stamina(delta: float) -> void:
	stamina = min(stamina + 25.0 * delta, max_stamina)

func _update_statuses(delta: float) -> void:
	_status_tick_timer -= delta
	if _status_tick_timer <= 0.0:
		_status_tick_timer = 1.0
		for status in _statuses.keys():
			_statuses[status]["duration"] -= 1.0
			if _statuses[status]["duration"] <= 0.0:
				_statuses.erase(status)

func _emit_all_stats() -> void:
	var stats = {
		"health": health,
		"max_health": max_health,
		"stamina": int(stamina),
		"max_stamina": int(max_stamina),
		"damage": base_damage + grit,
		"grit": grit,
	}
	stats_changed.emit(stats)
	_update_status_text()

func _update_status_text() -> void:
	if _statuses.is_empty():
		status_changed.emit("Status: steady")
		return
	
	var status_names = []
	for status in _statuses.keys():
		var duration = int(_statuses[status]["duration"])
		status_names.append("%s (%ds)" % [status.capitalize(), duration])
	
	status_changed.emit("Status: " + ", ".join(status_names))

func _on_attack_body_entered(body: Node2D) -> void:
	if body in _hit_targets or body == self:
		return
	
	if body.has_method("take_damage"):
		var damage = base_damage + grit
		body.take_damage(damage)
		_hit_targets.append(body)
		attack_landed.emit(body, damage)

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable") or area.has_method("interact"):
		_nearby_interactables.append(area)
		_update_nearest_interactable()

func _on_interaction_area_exited(area: Area2D) -> void:
	_nearby_interactables.erase(area)
	_update_nearest_interactable()

func _update_nearest_interactable() -> void:
	if _nearby_interactables.is_empty():
		_nearest_interactable = null
		interaction_changed.emit("")
		return
	
	var nearest = _nearby_interactables[0]
	var nearest_dist = position.distance_to(nearest.global_position)
	
	for interactable in _nearby_interactables:
		var dist = position.distance_to(interactable.global_position)
		if dist < nearest_dist:
			nearest = interactable
			nearest_dist = dist
	
	_nearest_interactable = nearest
	var label = ""
	if nearest.has_meta("interaction_label"):
		label = nearest.get_meta("interaction_label")
	interaction_changed.emit(label)

func take_damage(amount: int) -> void:
	if _invulnerable_timer > 0.0:
		return
	
	health -= amount
	_invulnerable_timer = 0.3
	if health <= 0:
		health = 0
		knocked_out.emit()
	_emit_all_stats()

func apply_status(status_name: String, duration: float, severity: float) -> void:
	_statuses[status_name.to_lower()] = {
		"duration": duration,
		"severity": severity,
	}
	_update_status_text()

func apply_item(item_data: Dictionary) -> void:
	var kind = item_data.get("kind", "")
	match kind:
		"food":
			health = min(health + 20, max_health)
			stamina = min(stamina + 15.0, max_stamina)
		"weapons":
			grit += 3
		"gear":
			health = min(health + 10, max_health)
		"fet_d":
			stamina = min(stamina + 35.0, max_stamina)
	_emit_all_stats()

func add_supply(amount: int) -> void:
	supplies += amount
	_emit_all_stats()

func clear_interactable(node: Node) -> void:
	_nearby_interactables.erase(node)
	_update_nearest_interactable()

func recover_between_phases(health_amount: int, stamina_amount: float) -> void:
	health = min(health + health_amount, max_health)
	stamina = min(stamina + stamina_amount, max_stamina)
	_emit_all_stats()
