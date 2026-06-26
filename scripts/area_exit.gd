extends Area2D

signal transition_requested(exit: Area2D)

@export var source_area := "outdoor_block"
@export var target_area := "outdoor_block"
@export var target_spawn := "default"
@export var display_name := ""

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player":
		transition_requested.emit(self)
