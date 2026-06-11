extends CharacterBody2D

signal defeated(enemy: Node, reward: int)
signal struck_player(damage: int)

@export var max_health := 38
@export var speed := 150.0
@export var damage := 11
@export var attack_range := 38.0
@export var attack_cooldown := 0.75
@export var reward := 2
@export var mood := "desperate"

@onready var body: Polygon2D = $Body
@onready var health_bar: ColorRect = $HealthBar/Fill

var health := max_health
var target: Node2D
var _attack_timer := randf_range(0.1, 0.45)
var _stun_timer := 0.0
var _knockback := Vector2.ZERO

func _ready() -> void:
	_update_health_bar()

func setup(new_target: Node2D, level: int = 1) -> void:
	target = new_target
	max_health += level * 6
	health = max_health
	speed += level * 8.0
	damage += level * 2
	reward += level
	_update_health_bar()

func _physics_process(delta: float) -> void:
	if target == null or health <= 0:
		return
	_attack_timer = max(0.0, _attack_timer - delta)
	_stun_timer = max(0.0, _stun_timer - delta)
	var to_target := target.global_position - global_position
	if _stun_timer > 0.0:
		velocity = _knockback.move_toward(Vector2.ZERO, 900.0 * delta)
		_knockback = velocity
	elif to_target.length() > attack_range:
		velocity = to_target.normalized() * speed
	else:
		velocity = Vector2.ZERO
		_try_attack()
	move_and_slide()

func take_hit(amount: int, direction: Vector2, attacker: Node = null) -> void:
	health = max(0, health - amount)
	_stun_timer = 0.16
	_knockback = direction.normalized() * 320.0
	_flash_hit()
	_update_health_bar()
	if health <= 0:
		if attacker != null and attacker.has_method("apply_status") and randf() < 0.18:
			attacker.call("apply_status", "psychosis", 8.0, 1.0)
		defeated.emit(self, reward)
		queue_free()

func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	_attack_timer = attack_cooldown
	if target != null and target.has_method("take_damage"):
		target.take_damage(damage, self)
		struck_player.emit(damage)

func _update_health_bar() -> void:
	if health_bar == null:
		return
	var ratio := 0.0
	if max_health > 0:
		ratio = float(health) / float(max_health)
	health_bar.scale.x = clamp(ratio, 0.0, 1.0)

func _flash_hit() -> void:
	body.color = Color(1.0, 0.82, 0.28, 1.0)
	await get_tree().create_timer(0.06).timeout
	if is_instance_valid(body):
		body.color = Color(0.78, 0.24, 0.19, 1.0)
