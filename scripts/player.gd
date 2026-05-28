extends CharacterBody2D

@export var speed := 260.0
@export var play_area := Rect2(24, 72, 912, 420)

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()
	position = position.clamp(play_area.position, play_area.position + play_area.size)

func reset_to(start_position: Vector2) -> void:
	position = start_position
	velocity = Vector2.ZERO
