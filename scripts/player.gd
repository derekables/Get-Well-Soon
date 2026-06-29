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
	print_debug("Player._ready start: position=", position, " play_area=", play_area)
	camera.make_current()
	# Try to bind play_area from the current scene's PlayArea node if present.
	_bind_play_area()
	print_debug("Player._ready after bind: play_area=", play_area)
	attack_area.body_entered.connect(_on_attack_body_entered)
	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	attack_area.monitoring = false
	attack_shape.disabled = true
	attack_arc.visible = false
	_emit_all_stats()

func _bind_play_area() -> void:
	# Get the active scene (the one you opened in the editor/run-time)
	var scene := get_tree().get_current_scene()
	if scene == null:
		print_debug("Player._bind_play_area: no current_scene")
		return
	# Look for a node named PlayArea under the current scene
	var pa := scene.get_node_or_null("PlayArea")
	if pa == null:
		print_debug("Player._bind_play_area: no PlayArea node found")
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
			print_debug("Player._bind_play_area: bound from get_rect(): ", play_area)
			return
		# Try position/size properties
		if pa.has_method("get_position") and pa.has_method("get_size"):
			var p = pa.get_position()
			var s = pa.get_size()
			play_area = Rect2(p, s)
			print_debug("Player._bind_play_area: bound from position/size: ", play_area)
			return
		# Nothing worked — leave default and log
		print_debug("Player._bind_play_area: could not read PlayArea offsets; using default: ", play_area)
		return

	# Compute Rect2 from offsets (cast to float defensively)
	var pos := Vector2(float(left), float(top))
	var size := Vector2(float(right) - float(left), float(bottom) - float(top))
	play_area = Rect2(pos, size)
	print_debug("Player._bind_play_area: bound from offsets: ", play_area)

func _physics_process(delta: float) -> void:
	_update_timers(delta)
	_update_statuses(delta)
	_handle_actions()
	_move_player(delta)
	_regenerate_stamina(delta)
	_emit_all_stats()

# rest of file unchanged
