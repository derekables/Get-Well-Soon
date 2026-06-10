extends Node2D

const TOTAL_SUPPLIES := 10
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const ITEM_SCENE := preload("res://scenes/item_pickup.tscn")
const PLAY_RECT := Rect2(24, 72, 912, 420)
const ITEM_TABLE := [
	{
		"kind": "bandage",
		"title": "Bandage",
		"description": "Heals a chunk of health.",
	},
	{
		"kind": "coffee",
		"title": "Gas Station Coffee",
		"description": "Stamina now, insomnia later. Faster movement and swings.",
	},
	{
		"kind": "street_meds",
		"title": "Unmarked Street Meds",
		"description": "Big heal, but withdrawal drains you over time.",
	},
	{
		"kind": "broken_bottle",
		"title": "Broken Bottle",
		"description": "Temporary weapon buff.",
	},
	{
		"kind": "scrap",
		"title": "Useful Scrap",
		"description": "Counts as supplies and restores a little stamina.",
	},
]

@onready var player = $Player
@onready var health_label: Label = $UI/MarginContainer/VBoxContainer/HealthLabel
@onready var stamina_label: Label = $UI/MarginContainer/VBoxContainer/StaminaLabel
@onready var score_label: Label = $UI/MarginContainer/VBoxContainer/ScoreLabel
@onready var status_label: Label = $UI/MarginContainer/VBoxContainer/StatusLabel
@onready var message_label: Label = $UI/MarginContainer/VBoxContainer/MessageLabel
@onready var restart_label: Label = $UI/MarginContainer/VBoxContainer/RestartLabel
@onready var combat_log_label: Label = $UI/MarginContainer/VBoxContainer/CombatLogLabel
@onready var coins: Node2D = $Coins
@onready var hazards: Node2D = $Hazards
@onready var enemies: Node2D = $Enemies
@onready var items: Node2D = $Items

var supplies := 0
var wave := 1
var start_position := Vector2.ZERO
var game_over := false
var _rng := RandomNumberGenerator.new()
var _combat_log := ""

func _ready() -> void:
	_rng.randomize()
	start_position = player.position
	player.stats_changed.connect(_on_player_stats_changed)
	player.status_changed.connect(_on_player_status_changed)
	player.attack_landed.connect(_on_attack_landed)
	player.knocked_out.connect(_on_player_knocked_out)
	for coin in coins.get_children():
		coin.collected.connect(_on_supply_collected)
	for hazard in hazards.get_children():
		hazard.touched.connect(_on_hazard_touched)
	_spawn_wave(wave)
	_spawn_loose_items(4)
	_set_log("Fast real-time combat online. Keep moving, dash through danger, and use whatever you find.")
	_update_ui()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()

func _on_supply_collected(coin: Area2D) -> void:
	if game_over:
		return
	supplies += 1
	player.add_supply(1)
	coin.queue_free()
	_set_log("Found supplies. Grit and stamina up.")
	if supplies >= TOTAL_SUPPLIES:
		_set_log("Supply run complete. You can keep fighting waves or press R to restart.")
	_update_ui()

func _on_hazard_touched() -> void:
	if game_over:
		return
	player.take_damage(8)
	player.apply_status("psychosis", 5.0, 1.0)
	_set_log("A bad contact rattled you: psychosis risk spiked.")

func _on_item_picked_up(item: Area2D, item_data: Dictionary) -> void:
	if game_over:
		return
	player.apply_item(item_data)
	if item_data.get("kind", "") == "scrap":
		supplies += 1
	_set_log("Picked up %s — %s" % [item_data.get("title", "Item"), item_data.get("description", "")])
	_update_ui()

func _on_enemy_defeated(enemy: Node, reward: int) -> void:
	if game_over:
		return
	_set_log("Dropped %s. +%d grit." % [enemy.name, reward])
	player.set("grit", player.get("grit") + reward)
	if _rng.randf() < 0.55:
		_spawn_item(enemy.global_position)
	if enemies.get_child_count() <= 1:
		wave += 1
		_spawn_wave(wave)
	_update_ui()

func _on_enemy_struck_player(damage: int) -> void:
	_set_log("Hit for %d. Dash, reposition, counter." % damage)

func _on_attack_landed(target: Node, damage: int) -> void:
	_set_log("Landed a fast hit on %s for %d." % [target.name, damage])

func _on_player_knocked_out() -> void:
	game_over = true
	message_label.text = "You got overwhelmed. Press R to try this block again."
	restart_label.text = "Restart: R"
	_set_log("Knocked out — tune the build, learn the rhythm, run it back.")

func _on_player_stats_changed(stats: Dictionary) -> void:
	health_label.text = "Health: %d / %d   Damage: %d" % [stats["health"], stats["max_health"], stats["damage"]]
	stamina_label.text = "Stamina: %d / %d   Grit: %d" % [stats["stamina"], stats["max_stamina"], stats["grit"]]
	score_label.text = "Supplies: %d / %d   Wave: %d" % [supplies, TOTAL_SUPPLIES, wave]

func _on_player_status_changed(status_text: String) -> void:
	status_label.text = status_text

func _spawn_wave(level: int) -> void:
	var count := min(2 + level, 7)
	for i in range(count):
		var enemy := ENEMY_SCENE.instantiate()
		enemy.name = "StreetThreat%d_%d" % [level, i + 1]
		enemy.global_position = _random_edge_position()
		enemies.add_child(enemy)
		enemy.setup(player, level)
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.struck_player.connect(_on_enemy_struck_player)
	_set_log("Wave %d rolled in: %d threats on the block." % [level, count])

func _spawn_loose_items(count: int) -> void:
	for i in range(count):
		_spawn_item(_random_play_position())

func _spawn_item(spawn_position: Vector2) -> void:
	var item := ITEM_SCENE.instantiate()
	var item_data: Dictionary = ITEM_TABLE[_rng.randi_range(0, ITEM_TABLE.size() - 1)]
	item.global_position = spawn_position.clamp(PLAY_RECT.position, PLAY_RECT.position + PLAY_RECT.size)
	items.add_child(item)
	item.configure(item_data)
	item.picked_up.connect(_on_item_picked_up)

func _random_play_position() -> Vector2:
	return Vector2(
		_rng.randf_range(PLAY_RECT.position.x + 24.0, PLAY_RECT.end.x - 24.0),
		_rng.randf_range(PLAY_RECT.position.y + 24.0, PLAY_RECT.end.y - 24.0)
	)

func _random_edge_position() -> Vector2:
	var side := _rng.randi_range(0, 3)
	match side:
		0:
			return Vector2(PLAY_RECT.position.x + 20.0, _rng.randf_range(PLAY_RECT.position.y, PLAY_RECT.end.y))
		1:
			return Vector2(PLAY_RECT.end.x - 20.0, _rng.randf_range(PLAY_RECT.position.y, PLAY_RECT.end.y))
		2:
			return Vector2(_rng.randf_range(PLAY_RECT.position.x, PLAY_RECT.end.x), PLAY_RECT.position.y + 20.0)
		_:
			return Vector2(_rng.randf_range(PLAY_RECT.position.x, PLAY_RECT.end.x), PLAY_RECT.end.y - 20.0)

func _set_log(text: String) -> void:
	_combat_log = text
	if combat_log_label != null:
		combat_log_label.text = "Log: " + _combat_log

func _update_ui() -> void:
	message_label.text = "Living the streets prototype: fast melee, stamina, grit, pickups, and risky status effects."
	restart_label.text = "Move: WASD/Arrows   Attack: Space/J   Dash: Shift/K   Restart: R"
	score_label.text = "Supplies: %d / %d   Wave: %d" % [supplies, TOTAL_SUPPLIES, wave]
	if combat_log_label != null:
		combat_log_label.text = "Log: " + _combat_log
