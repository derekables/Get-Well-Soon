extends Node2D

const STARTING_SUPPLY_CACHES := 18
const STARTING_PRESSURE_ZONES := 9
const STARTING_STORY_NODES := 7
const DAY_DURATION := 50.0
const NIGHT_DURATION := 65.0
const ENEMY_SCENE := preload("res://scenes/enemy.tscn")
const ITEM_SCENE := preload("res://scenes/item_pickup.tscn")
const SUPPLY_CACHE_SCENE := preload("res://scenes/supply_cache.tscn")
const PRESSURE_ZONE_SCENE := preload("res://scenes/pressure_zone.tscn")
const PLAY_RECT := Rect2(-1200, -900, 2400, 1800)
const SHOP_INTERIOR_RECT := Rect2(3000 - 284, -184, 568, 368)
const AREA_OUTDOOR := "outdoor_block"
const AREA_SHOP := "shop_interior"
const VIEWPORT_RECT := Rect2(24, 72, 912, 420)
const RESOURCE_TITLES := {
	"fet_d": "Fet-D",
	"food": "Food",
	"weapons": "Weapons",
	"gear": "Gear",
}

const BACKGROUNDS := [
	{
		"title": "Foster Kid",
		"description": "You learned to read rooms before you learned to trust them.",
		"hope": -4,
		"needs": {"belonging": -12, "safety": -6},
		"reputation": {"street": 1},
	},
	{
		"title": "Former Athlete",
		"description": "Your body remembers discipline even when your life does not.",
		"health": 14,
		"stamina": 12,
		"needs": {"purpose": -8},
	},
	{
		"title": "Street Hustler",
		"description": "You know who buys, who lies, and which doors never open twice.",
		"grit": 5,
		"items": {"weapons": 1},
		"reputation": {"street": 2, "criminal": 1},
	},
	{
		"title": "Musician",
		"description": "A few songs still make strangers stop and listen.",
		"hope": 6,
		"needs": {"purpose": 10, "self_worth": 6},
		"identity": {"creates_art": 2},
	},
]

const TRAITS := [
	{"title": "Fast Learner", "hope": 2, "identity": {"takes_responsibility": 1}},
	{"title": "Good Listener", "needs": {"belonging": 5}, "identity": {"builds_relationships": 1}},
	{"title": "Lucky", "items": {"food": 1}, "hope": 3},
	{"title": "Addictive Personality", "need_decay": 1.18, "hope": -2},
	{"title": "Insomnia", "status": "insomnia", "needs": {"sleep": -18}},
	{"title": "Impulsive", "identity": {"avoids_responsibility": 1}, "reputation": {"criminal": 1}},
	{"title": "Artist", "identity": {"creates_art": 1}, "needs": {"purpose": 4}},
]

const IDENTITY_TITLE_RULES := [
	{
		"title": "The Shepherd",
		"quote": "Everybody knows who you are. You're the Shepherd.",
		"weights": {"helps_strangers": 3, "builds_relationships": 2, "takes_responsibility": 1},
	},
	{
		"title": "The Provider",
		"quote": "People say you always find a way to keep others fed. The Provider, that's you.",
		"weights": {"shares_resources": 4, "helps_strangers": 2, "takes_responsibility": 1},
	},
	{
		"title": "The Dreamer",
		"quote": "Even out here, you're still chasing songs and impossible mornings. The Dreamer fits.",
		"weights": {"creates_art": 4, "purpose_kept": 1},
	},
	{
		"title": "The Wolf",
		"quote": "Folks step aside when you come through. They call you the Wolf now.",
		"weights": {"uses_violence": 4},
	},
	{
		"title": "The Ghost",
		"quote": "Nobody can pin you down. You're a ghost when things get close.",
		"weights": {"avoids_responsibility": 2, "survives_alone": 3},
	},
	{
		"title": "The Hustler",
		"quote": "Every block knows you can turn nothing into something. The Hustler, right?",
		"weights": {"chases_resources": 2, "lies": 2, "avoids_responsibility": 1},
	},
	{
		"title": "The Chameleon",
		"quote": "Recovery folks, street crews, businesses — you blend anywhere. Chameleon suits you.",
		"weights": {"changes_factions": 4, "builds_relationships": 1},
	},
	{
		"title": "The Survivor",
		"quote": "You keep getting through without becoming just one thing. That's a Survivor.",
		"weights": {"survival_days": 3, "takes_responsibility": 1, "chases_resources": 1},
	},
]

const STORY_TABLE := [
	{
		"title": "Homeless Veteran",
		"prompt": "A veteran is shaking beside a bus stop. You share time and supplies.",
		"supplies": -1,
		"hope": 4,
		"needs": {"belonging": 8, "self_worth": 8},
		"reputation": {"community": 2, "recovery": 1},
		"identity": {"helps_strangers": 2, "builds_relationships": 1, "shares_resources": 2},
	},
	{
		"title": "Open Mic Flyer",
		"prompt": "A torn flyer points to an open mic. You practice until your hands hurt.",
		"hope": 5,
		"needs": {"purpose": 12, "self_worth": 5, "sleep": -5},
		"reputation": {"community": 1},
		"identity": {"creates_art": 3, "purpose_kept": 1},
	},
	{
		"title": "Unlocked Delivery Door",
		"prompt": "Nobody is watching the delivery door. You slip in and grab what you can.",
		"items": {"food": 1, "gear": 1},
		"hope": -2,
		"reputation": {"criminal": 2, "employment": -1},
		"identity": {"lies": 1, "avoids_responsibility": 1, "chases_resources": 2},
	},
	{
		"title": "Recovery Meeting",
		"prompt": "A meeting is starting in a church basement. You sit in the back and listen.",
		"hope": 7,
		"needs": {"belonging": 10, "safety": 5},
		"reputation": {"recovery": 3, "community": 1},
		"identity": {"takes_responsibility": 2, "builds_relationships": 1, "changes_factions": 1},
	},
]

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
@onready var health_label: Label = $UI/MarginContainer/VBoxContainer/StatusPanel/StatusMargin/StatusVBox/HealthLabel
@onready var stamina_label: Label = $UI/MarginContainer/VBoxContainer/StatusPanel/StatusMargin/StatusVBox/StaminaLabel
@onready var score_label: Label = $UI/MarginContainer/VBoxContainer/TopBar/TopBarMargin/ScoreLabel
@onready var status_label: Label = $UI/MarginContainer/VBoxContainer/StatusPanel/StatusMargin/StatusVBox/StatusLabel
@onready var message_label: Label = $UI/MarginContainer/VBoxContainer/ObjectivePanel/ObjectiveMargin/MessageLabel
@onready var restart_label: Label = $UI/MarginContainer/VBoxContainer/RestartLabel
@onready var combat_log_label: Label = $UI/MarginContainer/VBoxContainer/LogPanel/LogMargin/CombatLogLabel
@onready var supply_caches: Node2D = $Supplies
@onready var pressure_zones: Node2D = $PressureZones
@onready var enemies: Node2D = $Enemies
@onready var items: Node2D = $Items
@onready var story_nodes: Node2D = $StoryNodes
@onready var shop_interior: Node2D = $ShopInterior
@onready var shop_entrance: Area2D = $ShopEntrance
@onready var shop_door_outside_spawn: Marker2D = $ShopDoorOutsideSpawn

var supplies := 0
var day := 1
var survived_nights := 0
var phase := "day"
var phase_time_remaining := DAY_DURATION
var wave := 1
var start_position := Vector2.ZERO
var current_area_name := AREA_OUTDOOR
var active_bounds := PLAY_RECT
var area_spawn_points := {}
var game_over := false
var survival_items := {
	"fet_d": 0,
	"food": 0,
	"weapons": 0,
	"gear": 0,
}
var _rng := RandomNumberGenerator.new()
var _combat_log := ""
var _recent_log_messages: Array[String] = []
var _last_resource_awarded := ""
var needs := {}
var reputation := {}
var identity := {}
var current_identity_title := ""
var identity_title_revealed := false
var _pending_identity_quote := ""
var hope := 50.0
var need_decay_multiplier := 1.0
var background := {}
var traits: Array = []
var _need_tick_timer := 0.0

func _ready() -> void:
	_rng.randomize()
	start_position = player.position
	area_spawn_points = {
		"default": start_position,
		"shop_spawn": shop_interior.global_position + shop_interior.get_node("ShopSpawn").position,
		"shop_door_outside": shop_door_outside_spawn.global_position,
	}
	_set_active_area(AREA_OUTDOOR, start_position, false, "")
	_connect_area_exits()
	player.stats_changed.connect(_on_player_stats_changed)
	player.status_changed.connect(_on_player_status_changed)
	player.attack_landed.connect(_on_attack_landed)
	player.knocked_out.connect(_on_player_knocked_out)
	_roll_character()
	_start_phase("day")
	_set_log("Day 1 started. Scavenge Fet-D, food, weapons, and gear before night falls.")
	_update_ui()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	if game_over:
		return
	_update_needs(delta)
	phase_time_remaining -= delta
	if phase_time_remaining <= 0.0:
		_complete_phase()
	_update_ui()

func _on_supply_collected(cache: Area2D) -> void:
	if game_over:
		return
	supplies += 1
	player.add_supply(1)
	_apply_identity_modifiers({"chases_resources": 1})
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
	_apply_item_need_effects(item_data)
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
	_apply_identity_modifiers({"uses_violence": 1})
	_set_log("Landed a fast hit on %s for %d." % [target.name, damage])

func _on_player_knocked_out() -> void:
	game_over = true
	message_label.text = "You got overwhelmed on %s %d. Press R to try this block again." % [phase.capitalize(), day]
	restart_label.text = "Restart: R"
	_set_log("Knocked out — tune the build, learn the rhythm, run it back.")

func _on_player_stats_changed(stats: Dictionary) -> void:
	health_label.text = "HP %d/%d   DMG %d" % [stats["health"], stats["max_health"], stats["damage"]]
	stamina_label.text = "STA %d/%d   Grit %d" % [stats["stamina"], stats["max_stamina"], stats["grit"]]
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
		_apply_identity_modifiers({"survival_days": 1})
		_start_phase("day")
		_set_log("Dawn broke. You survived %d night(s); requirements and danger increased." % survived_nights)

func _start_phase(new_phase: String) -> void:
	_set_active_area(AREA_OUTDOOR, start_position, false, "")
	phase = new_phase
	phase_time_remaining = DAY_DURATION if phase == "day" else NIGHT_DURATION
	wave = day if phase == "day" else day + survived_nights + 1
	_clear_container(supply_caches)
	_clear_container(pressure_zones)
	_clear_container(enemies)
	_clear_container(items)
	_clear_container(story_nodes)
	player.position = start_position
	player.velocity = Vector2.ZERO
	player.play_area = active_bounds
	if phase == "day":
		player.recover_between_phases(18 + day * 2, 55.0)
		_spawn_supply_caches(STARTING_SUPPLY_CACHES + day)
		_spawn_pressure_zones(STARTING_PRESSURE_ZONES + max(0, day - 1))
		_spawn_wave(max(1, day - 1))
		_spawn_loose_items(7 + min(day * 2, 10))
		_spawn_story_nodes(STARTING_STORY_NODES + min(day, 5))
	else:
		player.recover_between_phases(8, 25.0)
		_spawn_pressure_zones(STARTING_PRESSURE_ZONES + day + 2)
		_spawn_wave(wave)
		_spawn_loose_items(3 + min(day, 5))
		_spawn_story_nodes(2 + min(day, 4))
	_update_ui()

func _connect_area_exits() -> void:
	for node in get_tree().get_nodes_in_group("area_exit"):
		if node.has_signal("transition_requested"):
			node.transition_requested.connect(_on_area_transition_requested)

func _on_area_transition_requested(exit: Area2D) -> void:
	if game_over or exit.get("source_area") != current_area_name:
		return
	var spawn_name := str(exit.get("target_spawn"))
	var spawn_position: Vector2 = area_spawn_points.get(spawn_name, start_position)
	_set_active_area(str(exit.get("target_area")), spawn_position, true, str(exit.get("display_name")))

func _set_active_area(area_name: String, spawn_position: Vector2, clear_outdoor_entities: bool, title: String) -> void:
	current_area_name = area_name
	active_bounds = SHOP_INTERIOR_RECT if current_area_name == AREA_SHOP else PLAY_RECT
	shop_interior.visible = current_area_name == AREA_SHOP
	player.play_area = active_bounds
	player.position = spawn_position.clamp(active_bounds.position, active_bounds.position + active_bounds.size)
	player.velocity = Vector2.ZERO
	if player.camera != null:
		player.camera.limit_left = int(active_bounds.position.x)
		player.camera.limit_top = int(active_bounds.position.y)
		player.camera.limit_right = int(active_bounds.end.x)
		player.camera.limit_bottom = int(active_bounds.end.y)
	if clear_outdoor_entities and current_area_name == AREA_SHOP:
		_clear_outdoor_procedural_entities()
	if title != "":
		_set_log(title)
		message_label.text = title

func _clear_outdoor_procedural_entities() -> void:
	_clear_container(supply_caches)
	_clear_container(pressure_zones)
	_clear_container(enemies)
	_clear_container(items)
	_clear_container(story_nodes)

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

func _spawn_story_nodes(count: int) -> void:
	for i in range(count):
		var node := Area2D.new()
		node.name = "StoryNode%d" % (i + 1)
		node.global_position = _random_play_position()
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 28.0
		shape.shape = circle
		node.add_child(shape)
		var marker := Polygon2D.new()
		marker.color = Color(0.2, 0.52, 1.0, 0.76)
		marker.polygon = PackedVector2Array(Vector2(0, -24), Vector2(22, 0), Vector2(0, 24), Vector2(-22, 0))
		node.add_child(marker)
		var story_data: Dictionary = STORY_TABLE[_rng.randi_range(0, STORY_TABLE.size() - 1)]
		node.set_meta("story_data", story_data)
		story_nodes.add_child(node)
		node.body_entered.connect(_on_story_node_entered.bind(node))

func _spawn_loose_items(count: int) -> void:
	for i in range(count):
		_spawn_item(_random_play_position())

func _spawn_item(spawn_position: Vector2) -> void:
	var item := ITEM_SCENE.instantiate()
	var item_data: Dictionary = ITEM_TABLE[_rng.randi_range(0, ITEM_TABLE.size() - 1)]
	item.global_position = spawn_position.clamp(active_bounds.position, active_bounds.position + active_bounds.size)
	items.add_child(item)
	item.configure(item_data)
	item.picked_up.connect(_on_item_picked_up)

func _random_play_position() -> Vector2:
	return Vector2(
		_rng.randf_range(active_bounds.position.x + 44.0, active_bounds.end.x - 44.0),
		_rng.randf_range(active_bounds.position.y + 44.0, active_bounds.end.y - 44.0)
	)

func _random_edge_position() -> Vector2:
	var side := _rng.randi_range(0, 3)
	match side:
		0:
			return Vector2(active_bounds.position.x + 20.0, _rng.randf_range(active_bounds.position.y, active_bounds.end.y))
		1:
			return Vector2(active_bounds.end.x - 20.0, _rng.randf_range(active_bounds.position.y, active_bounds.end.y))
		2:
			return Vector2(_rng.randf_range(active_bounds.position.x, active_bounds.end.x), active_bounds.position.y + 20.0)
		_:
			return Vector2(_rng.randf_range(active_bounds.position.x, active_bounds.end.x), active_bounds.end.y - 20.0)

func _on_story_node_entered(body: Node, node: Area2D) -> void:
	if game_over or body != player or not is_instance_valid(node):
		return
	var story_data: Dictionary = node.get_meta("story_data", {})
	_apply_story_node(story_data)
	node.queue_free()

func _apply_story_node(story_data: Dictionary) -> void:
	if story_data.is_empty():
		return
	supplies = max(0, supplies + int(story_data.get("supplies", 0)))
	_adjust_hope(float(story_data.get("hope", 0.0)))
	_apply_need_modifiers(story_data.get("needs", {}))
	_apply_reputation_modifiers(story_data.get("reputation", {}))
	_apply_identity_modifiers(story_data.get("identity", {}))
	for resource in story_data.get("items", {}).keys():
		_add_survival_item(resource, int(story_data["items"][resource]))
	_set_log("%s: %s" % [story_data.get("title", "Story"), story_data.get("prompt", "The city remembers.")])
	_update_ui()

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

func _roll_character() -> void:
	needs = {"hunger": 82.0, "thirst": 78.0, "sleep": 74.0, "hygiene": 58.0, "warmth": 68.0, "safety": 56.0, "belonging": 42.0, "purpose": 38.0, "self_worth": 44.0}
	reputation = {"street": 0, "criminal": 0, "recovery": 0, "employment": 0, "community": 0}
	identity = {"helps_strangers": 0, "lies": 0, "creates_art": 0, "uses_violence": 0, "builds_relationships": 0, "takes_responsibility": 0, "avoids_responsibility": 0, "shares_resources": 0, "chases_resources": 0, "changes_factions": 0, "survives_alone": 0, "survival_days": 0, "purpose_kept": 0}
	background = BACKGROUNDS[_rng.randi_range(0, BACKGROUNDS.size() - 1)]
	traits.clear()
	var pool := TRAITS.duplicate()
	for i in range(3):
		var idx := _rng.randi_range(0, pool.size() - 1)
		traits.append(pool.pop_at(idx))
	_apply_origin(background)
	for trait in traits:
		_apply_origin(trait)
	player.max_health += int(background.get("health", 0))
	player.max_stamina += float(background.get("stamina", 0.0))
	player.health = player.max_health
	player.stamina = player.max_stamina
	player.grit += int(background.get("grit", 0))

func _apply_origin(origin: Dictionary) -> void:
	_adjust_hope(float(origin.get("hope", 0.0)))
	need_decay_multiplier *= float(origin.get("need_decay", 1.0))
	_apply_need_modifiers(origin.get("needs", {}))
	_apply_reputation_modifiers(origin.get("reputation", {}))
	_apply_identity_modifiers(origin.get("identity", {}))
	for resource in origin.get("items", {}).keys():
		_add_survival_item(resource, int(origin["items"][resource]))
	if origin.has("status"):
		player.apply_status(origin["status"], 18.0, 1.0)

func _update_needs(delta: float) -> void:
	_need_tick_timer -= delta
	var day_pressure := 1.0 + float(day - 1) * 0.08
	needs["hunger"] = max(0.0, needs["hunger"] - 0.75 * delta * day_pressure * need_decay_multiplier)
	needs["thirst"] = max(0.0, needs["thirst"] - 0.95 * delta * day_pressure * need_decay_multiplier)
	needs["sleep"] = max(0.0, needs["sleep"] - (0.44 if phase == "day" else 0.82) * delta * need_decay_multiplier)
	needs["hygiene"] = max(0.0, needs["hygiene"] - 0.18 * delta * need_decay_multiplier)
	needs["warmth"] = max(0.0, needs["warmth"] - (0.18 if phase == "day" else 0.52) * delta * day_pressure)
	needs["safety"] = max(0.0, needs["safety"] - (0.2 if phase == "day" else 0.72) * delta * day_pressure)
	needs["belonging"] = max(0.0, needs["belonging"] - 0.12 * delta)
	needs["purpose"] = max(0.0, needs["purpose"] - 0.1 * delta)
	needs["self_worth"] = max(0.0, needs["self_worth"] - 0.1 * delta)
	if _need_tick_timer <= 0.0:
		_need_tick_timer = 4.0
		_resolve_need_consequences()

func _resolve_need_consequences() -> void:
	var lowest := 100.0
	for value in needs.values():
		lowest = min(lowest, float(value))
	if lowest < 18.0:
		player.take_damage(2 + day)
		_adjust_hope(-2.0)
	if needs.get("sleep", 100.0) < 24.0:
		player.apply_status("insomnia", 6.0, 1.0)
	if needs.get("safety", 100.0) < 20.0:
		player.apply_status("psychosis", 5.0, 1.0)
	if needs.get("purpose", 100.0) < 18.0 or needs.get("self_worth", 100.0) < 18.0:
		_adjust_hope(-1.0)
	if needs.get("belonging", 100.0) < 20.0:
		_apply_identity_modifiers({"survives_alone": 1})
	if needs.get("purpose", 0.0) > 70.0:
		_apply_identity_modifiers({"purpose_kept": 1})

func _apply_item_need_effects(item_data: Dictionary) -> void:
	match item_data.get("kind", "scrap"):
		"food":
			_apply_need_modifiers({"hunger": 24, "thirst": 8})
		"coffee":
			_apply_need_modifiers({"thirst": 6, "sleep": -8})
		"gear":
			_apply_need_modifiers({"warmth": 18, "safety": 6})
		"fet_d", "street_meds":
			_apply_need_modifiers({"safety": 4})
		_:
			_apply_need_modifiers({"purpose": 2})

func _apply_need_modifiers(modifiers: Dictionary) -> void:
	for key in modifiers.keys():
		if needs.has(key):
			needs[key] = clamp(float(needs[key]) + float(modifiers[key]), 0.0, 100.0)

func _apply_reputation_modifiers(modifiers: Dictionary) -> void:
	for key in modifiers.keys():
		if reputation.has(key):
			reputation[key] += int(modifiers[key])

func _apply_identity_modifiers(modifiers: Dictionary) -> void:
	for key in modifiers.keys():
		if identity.has(key):
			identity[key] += int(modifiers[key])
	_update_identity_title()

func _update_identity_title() -> void:
	var best_title := ""
	var best_quote := ""
	var best_score := 0
	for rule in IDENTITY_TITLE_RULES:
		var score := 0
		for key in rule.get("weights", {}).keys():
			score += int(identity.get(key, 0)) * int(rule["weights"][key])
		if score > best_score:
			best_score = score
			best_title = rule.get("title", "")
			best_quote = rule.get("quote", "")
	current_identity_title = best_title
	if not identity_title_revealed and best_score >= 10 and best_quote != "":
		identity_title_revealed = true
		_pending_identity_quote = best_quote

func _identity_title_score() -> int:
	var best_score := 0
	for rule in IDENTITY_TITLE_RULES:
		var score := 0
		for key in rule.get("weights", {}).keys():
			score += int(identity.get(key, 0)) * int(rule["weights"][key])
		best_score = max(best_score, score)
	return best_score


func _adjust_hope(amount: float) -> void:
	hope = clamp(hope + amount, 0.0, 100.0)

func _format_timer() -> String:
	var seconds := int(ceil(max(0.0, phase_time_remaining)))
	return "%02d:%02d" % [int(seconds / 60), seconds % 60]

func _needs_text() -> String:
	var alerts: Array[String] = []
	var checks := {
		"hunger": "Hungry",
		"thirst": "Thirsty",
		"sleep": "Exhausted",
		"hygiene": "Dirty",
		"warmth": "Cold",
		"safety": "Unsafe",
		"belonging": "Isolated",
		"purpose": "Aimless",
		"self_worth": "Shaken",
	}
	for key in checks.keys():
		if float(needs.get(key, 100.0)) < 45.0:
			alerts.append(checks[key])
	if alerts.is_empty():
		alerts.append("Stable")
	var visible_alerts := alerts.slice(0, 2)
	visible_alerts.append("Hope %s" % _hope_trend())
	return "Needs: %s" % " / ".join(visible_alerts)

func _hope_trend() -> String:
	if hope >= 70.0:
		return "rising"
	if hope >= 40.0:
		return "fragile"
	if hope >= 18.0:
		return "fading"
	return "dangerously low"

func _identity_text() -> String:
	var trait_titles: Array[String] = []
	for trait in traits:
		trait_titles.append(trait.get("title", "Trait"))
	var whisper := "Nobody has named what you're becoming yet."
	if identity_title_revealed:
		whisper = "People are starting to call you %s." % current_identity_title
	elif _identity_title_score() >= 6:
		whisper = "People are starting to recognize a pattern in you."
	return "Background: %s | Traits: %s | Rumor: %s | Rep S/C/R/E/Com: %d/%d/%d/%d/%d" % [
		background.get("title", "Unknown"), ", ".join(trait_titles), whisper,
		reputation["street"], reputation["criminal"], reputation["recovery"], reputation["employment"], reputation["community"],
	]


func _requirements_text() -> String:
	var requirements := _resource_requirement()
	var parts: Array[String] = []
	for resource in requirements.keys():
		var owned := int(survival_items.get(resource, 0))
		var required := int(requirements[resource])
		if owned < required:
			parts.append("%s %d/%d" % [RESOURCE_TITLES.get(resource, resource.capitalize()), owned, required])
	if parts.is_empty():
		return "Ready for night. Spare supplies: %d" % supplies
	return "Need: %s | Scrap: %d" % [", ".join(parts), supplies]

func _inventory_text() -> String:
	var stocked: Array[String] = []
	for resource in survival_items.keys():
		var amount := int(survival_items[resource])
		if amount > 0:
			stocked.append("%s x%d" % [RESOURCE_TITLES.get(resource, resource.capitalize()), amount])
	if supplies > 0:
		stocked.append("Scrap x%d" % supplies)
	if stocked.is_empty():
		return "Pack: empty"
	return "Pack: %s" % ", ".join(stocked.slice(0, 4))

func _set_log(text: String) -> void:
	if _pending_identity_quote != "" and text != _pending_identity_quote:
		text = "%s / %s" % [text, _pending_identity_quote]
		_pending_identity_quote = ""
	_recent_log_messages.push_front(text)
	if _recent_log_messages.size() > 2:
		_recent_log_messages.resize(2)
	_combat_log = "\n".join(_recent_log_messages)
	if combat_log_label != null:
		combat_log_label.text = "Log\n" + _combat_log

func _update_score_label() -> void:
	if score_label == null:
		return
	score_label.text = "%s %d   %s   Danger %d   Nights %d" % [phase.to_upper(), day, _format_timer(), wave, survived_nights]

func _update_ui() -> void:
	if game_over:
		_update_score_label()
		return
	if phase == "day":
		message_label.text = "Objective: gather essentials before nightfall.\n%s\n%s" % [_requirements_text(), _needs_text()]
	else:
		message_label.text = "Objective: survive until dawn. Keep moving.\n%s\n%s" % [_inventory_text(), _needs_text()]
	restart_label.text = "%s\nControls: WASD/Arrows move   Space/J attack   Shift/K dash   R restart" % _identity_text()
	_update_score_label()
	if combat_log_label != null:
		combat_log_label.text = "Log\n" + _combat_log
