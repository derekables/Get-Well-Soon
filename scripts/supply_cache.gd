extends Area2D

signal collected(cache: Area2D)

@export var interaction_label := "Search Supply Cache"

func get_interaction_label() -> String:
	return interaction_label

func interact(_player_or_game: Node) -> void:
	collected.emit(self)
