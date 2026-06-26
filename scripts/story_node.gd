extends Area2D

var story_data := {}

func configure(data: Dictionary) -> void:
	story_data = data
	set_meta("story_data", story_data)

func get_interaction_label() -> String:
	return story_data.get("title", "Story")

func interact(game: Node) -> void:
	if game != null and game.has_method("resolve_story_node"):
		game.resolve_story_node(self)
