extends Node2D

const TOTAL_COINS := 10

@onready var player: CharacterBody2D = $Player
@onready var score_label: Label = $UI/MarginContainer/VBoxContainer/ScoreLabel
@onready var message_label: Label = $UI/MarginContainer/VBoxContainer/MessageLabel
@onready var restart_label: Label = $UI/MarginContainer/VBoxContainer/RestartLabel
@onready var coins: Node2D = $Coins
@onready var hazards: Node2D = $Hazards

var score := 0
var start_position := Vector2.ZERO
var game_won := false

func _ready() -> void:
	start_position = player.position
	for coin in coins.get_children():
		coin.collected.connect(_on_coin_collected)
	for hazard in hazards.get_children():
		hazard.touched.connect(_on_hazard_touched)
	_update_ui()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func _on_coin_collected(coin: Area2D) -> void:
	if game_won:
		return
	score += 1
	coin.queue_free()
	if score >= TOTAL_COINS:
		game_won = true
		message_label.text = "You collected every heart. Get well soon!"
		restart_label.text = "Press R to play again."
	else:
		_update_ui()

func _on_hazard_touched() -> void:
	if game_won:
		return
	player.reset_to(start_position)
	message_label.text = "Ouch! A germ touched you. Back to bed!"

func _update_ui() -> void:
	score_label.text = "Hearts: %d / %d" % [score, TOTAL_COINS]
	message_label.text = "Collect all hearts while avoiding the germs."
	restart_label.text = "Move: WASD or Arrow Keys   Restart: R"
