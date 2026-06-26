extends Area2D

signal collected(cache: Area2D)

func get_interaction_label() -> String:
	return "Search Supply Cache"

func interact(_game: Node) -> void:
	collected.emit(self)
