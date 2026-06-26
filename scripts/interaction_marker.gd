extends Area2D

signal interacted(marker: Area2D)

@export var interaction_label := "Interact"

func get_interaction_label() -> String:
	return interaction_label

func interact(_game: Node) -> void:
	interacted.emit(self)
