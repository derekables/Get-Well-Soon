extends Node2D

const STARTING_SUPPLY_CACHES := 8
const STARTING_PRESSURE_ZONES := 4
const DAY_DURATION := 50.0
const NIGHT_DURATION := 65.0
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const ITEM_SCENE := preload("res://scenes/item_pickup.tscn")
const SUPPLY_CACHE_SCENE := preload("res://scenes/supply_cache.tscn")
const PRESSURE_ZONE_SCENE := preload("res://scenes/pressure_zone.tscn")
const PLAY_RECT := Rect2(24, 72, 912, 420)
const RESOURCE_TITLES := {
	"fet_d": "Fet-D",
	"food": "Food",
	"weapons": "Weapons",
	"gear": "Gear",
}
const ITEM_TABLE := [
	{
		"kind": "fet_d",
		"title": "Fet-D",
		"description": "Keeps withdrawal away long enough to stay well.",
		"resource": "fet_d",
		"amount": 1,
	},
	{
		"kind": "food",
		"title": "Convenience Store Food",
		"description": "Calories for the next cold stretch.",
		"resource": "food",
		"amount": 1,
	},
	{
		"kind": "weapon",
		"title": "Pipe Wrench",
		"description": "A real weapon for the night push.",
		"resource": "weapons",
		"amount": 1,
	},
	{
		"kind": "gear",
		"title": "Layered Hoodie",
		"description": "Equipment that helps you last outside.",
		"resource": "gear",
		"amount": 1,
	},
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
		"description": "Flexible supplies that help cover any missing need.",
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
@onready var supply_caches: Node2D = $Supplies
@onready var pressure_zones: Node2D = $PressureZones
@onready var enemies: Node2D = $Enemies
@onready var items: Node2D = $Items

var supplies := 0
var day := 1
var survived_nights := 0
var phase := "day"
var phase_time_remaining := DAY_DURATION
var wave := 1
var start_position := Vector2.ZERO
var game_over := false
var survival_items := {
	"fet_d": 0,
	"food": 0,
	"weapons": 0,
	"gear": 0,
}
var _rng := RandomNumberGenerator.new()
var _combat_log := ""
var _last_resource_awarded := ""

func _ready() -> void:
	_rng.randomize()
	start_position = player.position
	player.stats_changed.connect(_on_player_stats_changed)
	player.status_changed.connect(_on_player_status_changed)
	player.attack_landed.connect(_on_attack_landed)
	player.knocked_out.connect(_on_player_knocked_out)
	_start_phase("day")
	_set_log("Day 1 started. Scavenge Fet-D, food, weapons, and gear before night falls.")
	_update_ui()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if game_over:
		return
	phase_time_remaining -= delta
	if phase_time_remaining <= 0.0:
		_complete_phase()
	_update_ui()

func _on_supply_collected(cache: Area2D) -> void:
	if game_over:
		return
	supplies += 1
	player.add_supply(1)
	cache.queue_free()
	var resource := _award_random_survival_item()
	_set_log("Found a cache: +1 %s plus grit and stamina." % RESOURCE_TITLES.get(resource, resource.capitalize()))
	_update_ui()

func _on_pressure_zone_triggered() -> void:
	if game_over:
		return
	var damage := 7 + day
	if phase == "night":
		damage += 3
	player.take_damage(damage)
	player.apply_status("psychosis", 4.0 + float(day), 1.0)
	_set_log("A %s pressure zone rattled you: psychosis risk spiked." % phase)

func _on_item_picked_up(item: Area2D, item_data: Dictionary) -> void:
	if game_over:
		return
	player.apply_item(item_data)
	var resource := item_data.get("resource", "")
	if resource != "":
		_add_survival_item(resource, item_data.get("amount", 1))
	elif item_data.get("kind", "") == "scrap":
		supplies += 1
	_set_log("Picked up %s — %s" % [item_data.get("title", "Item"), item_data.get("description", "")])
	_update_ui()

func _on_enemy_defeated(enemy: Node, reward: int) -> void:
	if game_over:
		return
	_set_log("Dropped %s. +%d grit." % [enemy.name, reward])
	player.set("grit", player.get("grit") + reward)
	if _rng.randf() < _drop_chance():
		_spawn_item(enemy.global_position)
	if phase == "night" and enemies.get_child_count() <= 1:
		wave += 1
		_spawn_wave(wave)
	_update_ui()

func _on_enemy_struck_player(damage: int) -> void:
	_set_log("Hit for %d during %s. Dash, reposition, counter." % [damage, phase])

func _on_attack_landed(target: Node, damage: int) -> void:
	_set_log("Landed a fast hit on %s for %d." % [target.name, damage])

func _on_player_knocked_out() -> void:
	game_over = true
	message_label.text = "You got overwhelmed on %s %d. Press R to try this block again." % [phase.capitalize(), day]
	restart_label.text = "Restart: R"
	_set_log("Knocked out — tune the build, learn the rhythm, run it back.")

func _on_player_stats_changed(stats: Dictionary) -> void:
	health_label.text = "Health: %d / %d   Damage: %d" % [stats["health"], stats["max_health"], stats["damage"]]
	stamina_label.text = "Stamina: %d / %d   Grit: %d" % [stats["stamina"], stats["max_stamina"], stats["grit"]]
	_update_score_label()

func _on_player_status_changed(status_text: String) -> void:
	status_label.text = status_text

func _complete_phase() -> void:
	if phase == "day":
		if _has_required_supplies():
			_consume_required_supplies()
			_start_phase("night")
			_set_log("Night %d began. You had enough supplies; now survive until dawn." % day)
		else:
			_fail_for_missing_supplies()
	else:
		survived_nights += 1
		day += 1
		_start_phase("day")
		_set_log("Dawn broke. You survived %d night(s); requirements and danger increased." % survived_nights)

func _start_phase(new_phase: String) -> void:
	phase = new_phase
	phase_time_remaining = DAY_DURATION if phase == "day" else NIGHT_DURATION
	wave = day if phase == "day" else day + survived_nights + 1
	_clear_container(supply_caches)
	_clear_container(pressure_zones)
	_clear_container(enemies)
	_clear_container(items)
	player.position = start_position
	player.velocity = Vector2.ZERO
	if phase == "day":
		player.recover_between_phases(18 + day * 2, 55.0)
		_spawn_supply_caches(STARTING_SUPPLY_CACHES + day)
		_spawn_pressure_zones(STARTING_PRESSURE_ZONES + max(0, day - 1))
		_spawn_wave(max(1, day - 1))
		_spawn_loose_items(3 + min(day, 4))
	else:
		player.recover_between_phases(8, 25.0)
		_spawn_pressure_zones(STARTING_PRESSURE_ZONES + day + 2)
		_spawn_wave(wave)
		_spawn_loose_items(1 + min(day, 3))
	_update_ui()

func _spawn_wave(level: int) -> void:
	var count := 0
	if phase == "day":
		count = min(1 + day, 5)
	else:
		count = min(3 + day + survived_nights, 9)
	for i in range(count):
		var enemy := ENEMY_SCENE.instantiate()
		enemy.name = "%sThreat%d_%d" % [phase.capitalize(), level, i + 1]
		enemy.global_position = _random_edge_position()
		enemies.add_child(enemy)
		enemy.setup(player, level)
		enemy.defeated.connect(_on_enemy_defeated)
		enemy.struck_player.connect(_on_enemy_struck_player)
	_set_log("%s %d danger level %d: %d threats on the block." % [phase.capitalize(), day, level, count])

func _spawn_supply_caches(count: int) -> void:
	for i in range(count):
		var cache := SUPPLY_CACHE_SCENE.instantiate()
		cache.name = "SupplyCache%d" % (i + 1)
		cache.global_position = _random_play_position()
		supply_caches.add_child(cache)
		cache.collected.connect(_on_supply_collected)

func _spawn_pressure_zones(count: int) -> void:
	for i in range(count):
		var zone := PRESSURE_ZONE_SCENE.instantiate()
		zone.name = "%sPressureZone%d" % [phase.capitalize(), i + 1]
		zone.global_position = _random_play_position()
		pressure_zones.add_child(zone)
		zone.triggered.connect(_on_pressure_zone_triggered)

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
		_rng.randf_range(PLAY_RECT.position.x + 44.0, PLAY_RECT.end.x - 44.0),
		_rng.randf_range(PLAY_RECT.position.y + 44.0, PLAY_RECT.end.y - 44.0)
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

func _award_random_survival_item() -> String:
	var keys := survival_items.keys()
	var resource := str(keys[_rng.randi_range(0, keys.size() - 1)])
	_add_survival_item(resource, 1)
	return resource

func _add_survival_item(resource: String, amount: int) -> void:
	if not survival_items.has(resource):
		return
	survival_items[resource] += amount
	_last_resource_awarded = resource

func _resource_requirement() -> Dictionary:
	return {
		"fet_d": 1 + int(floor(float(day - 1) / 2.0)),
		"food": 1 + day,
		"weapons": 1 + int(floor(float(day) / 3.0)),
		"gear": 1 + int(floor(float(day - 1) / 2.0)),
	}

func _has_required_supplies() -> bool:
	var requirements := _resource_requirement()
	var flexible_supplies := supplies
	for resource in requirements.keys():
		var required := int(requirements[resource])
		var owned := int(survival_items.get(resource, 0))
		var missing: int = max(0, required - owned)
		flexible_supplies -= missing
		if flexible_supplies < 0:
			return false
	return true

func _consume_required_supplies() -> void:
	var requirements := _resource_requirement()
	var flexible_supplies := supplies
	for resource in requirements.keys():
		var needed := int(requirements[resource])
		var used_specific: int = min(int(survival_items.get(resource, 0)), needed)
		survival_items[resource] -= used_specific
		var missing := needed - used_specific
		flexible_supplies -= missing
	supplies = max(0, flexible_supplies)

func _fail_for_missing_supplies() -> void:
	game_over = true
	var missing := _missing_supply_text()
	message_label.text = "Night %d was not survivable. Missing: %s." % [day, missing]
	restart_label.text = "Restart: R"
	_set_log("You did not collect enough Fet-D, food, weapons, and gear before nightfall.")
	_update_ui()

func _missing_supply_text() -> String:
	var requirements := _resource_requirement()
	var missing_parts: Array[String] = []
	var flexible_supplies := supplies
	for resource in requirements.keys():
		var required := int(requirements[resource])
		var owned := int(survival_items.get(resource, 0))
		var missing: int = max(0, required - owned)
		if missing > 0:
			var covered_by_supplies: int = min(flexible_supplies, missing)
			flexible_supplies -= covered_by_supplies
			missing -= covered_by_supplies
		if missing > 0:
			missing_parts.append("%s x%d" % [RESOURCE_TITLES.get(resource, resource.capitalize()), missing])
	if missing_parts.is_empty():
		return "nothing"
	return ", ".join(missing_parts)

func _drop_chance() -> float:
	if phase == "night":
		return 0.38
	return 0.58

func _clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()

func _format_timer() -> String:
	var seconds := int(ceil(max(0.0, phase_time_remaining)))
	return "%02d:%02d" % [int(seconds / 60), seconds % 60]

func _requirements_text() -> String:
	var requirements := _resource_requirement()
	var parts: Array[String] = []
	for resource in requirements.keys():
		parts.append("%s %d/%d" % [RESOURCE_TITLES.get(resource, resource.capitalize()), survival_items.get(resource, 0), requirements[resource]])
	return "   ".join(parts)

func _inventory_text() -> String:
	return "Fet-D:%d Food:%d Weapons:%d Gear:%d Supplies:%d" % [
		survival_items["fet_d"],
		survival_items["food"],
		survival_items["weapons"],
		survival_items["gear"],
		supplies,
	]

func _set_log(text: String) -> void:
	_combat_log = text
	if combat_log_label != null:
		combat_log_label.text = "Log: " + _combat_log

func _update_score_label() -> void:
	if score_label == null:
		return
	score_label.text = "%s %d  Time: %s  Nights: %d  Danger: %d" % [phase.capitalize(), day, _format_timer(), survived_nights, wave]

func _update_ui() -> void:
	if game_over:
		_update_score_label()
		return
	if phase == "day":
		message_label.text = "Day %d: collect enough for tonight — %s" % [day, _requirements_text()]
	else:
		message_label.text = "Night %d: survive until dawn. Inventory left: %s" % [day, _inventory_text()]
	restart_label.text = "Move: WASD/Arrows   Attack: Space/J   Dash: Shift/K   Restart: R"
	_update_score_label()
	if combat_log_label != null:
		combat_log_label.text = "Log: " + _combat_log
