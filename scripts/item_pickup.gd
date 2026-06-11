extends Area2D

signal picked_up(item: Area2D, item_data: Dictionary)

@export var kind := "scrap"
@export var title := "Scrap"
@export_multiline var description := "Something useful, maybe."

@onready var shape: Polygon2D = $Shape

const ITEM_COLORS := {
	"bandage": Color(0.95, 0.95, 0.86, 1.0),
	"coffee": Color(0.47, 0.29, 0.16, 1.0),
	"street_meds": Color(0.61, 0.46, 0.96, 1.0),
	"broken_bottle": Color(0.35, 0.83, 0.78, 1.0),
	"scrap": Color(0.72, 0.72, 0.72, 1.0),
}

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	shape.color = ITEM_COLORS.get(kind, ITEM_COLORS["scrap"])

func configure(item_data: Dictionary) -> void:
	kind = item_data.get("kind", kind)
	title = item_data.get("title", title)
	description = item_data.get("description", description)
	if shape != null:
		shape.color = ITEM_COLORS.get(kind, ITEM_COLORS["scrap"])

func _on_body_entered(body: Node2D) -> void:
	if body.name != "Player":
		return
	picked_up.emit(self, {
		"kind": kind,
		"title": title,
		"description": description,
	})
	queue_free()
