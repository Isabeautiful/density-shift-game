extends Node3D

@export var enemy_scene: PackedScene
@export var max_enemies: int = 15
@export var spawn_radius: float = 40.0
@export var min_spawn_height: float = 5.0
@export var max_spawn_height: float = 25.0
@export var spawn_interval: float = 5.0
@export var spawn_on_start: bool = true
@export var spawn_near_player: bool = true
@export var player_proximity_range: float = 20.0
@export var enabled: bool = true
@export var enemy_lifetime: float = 60.0

var player: CharacterBody3D = null
var enemies: Array = []
var spawn_timer: float = 0.0
var is_active: bool = true

func _ready():
	find_player()
	
	if spawn_on_start and enabled:
		var initial_count = min(max_enemies, 5)
		for i in range(initial_count):
			spawn_enemy()

func _physics_process(delta):
	if not is_active or not enabled or player == null:
		return
	
	spawn_timer += delta
	
	if spawn_timer >= spawn_interval and enemies.size() < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0
	
	cleanup_enemies()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func spawn_enemy():
	if enemy_scene == null:
		return
	
	if player == null:
		find_player()
		if player == null:
			return
	
	var spawn_position = Vector3.ZERO
	var spawn_attempts = 0
	var max_attempts = 5
	var valid_position = false
	
	while not valid_position and spawn_attempts < max_attempts:
		var angle = randf() * 2 * PI
		var distance = randf_range(player_proximity_range * 0.5, player_proximity_range * 1.5)
		
		spawn_position = player.global_position + Vector3(
			cos(angle) * distance,
			randf_range(min_spawn_height, max_spawn_height),
			sin(angle) * distance
		)
		
		var half_radius = spawn_radius / 2.0
		if (abs(spawn_position.x) > half_radius or 
			abs(spawn_position.z) > half_radius):
			spawn_attempts += 1
			continue
		
		var too_close = false
		for enemy in enemies:
			if is_instance_valid(enemy):
				var distance_to_enemy = spawn_position.distance_to(enemy.global_position)
				if distance_to_enemy < 5.0:
					too_close = true
					break
		
		if not too_close:
			valid_position = true
		
		spawn_attempts += 1
	
	if not valid_position:
		spawn_position = Vector3(
			randf_range(-spawn_radius, spawn_radius),
			randf_range(min_spawn_height, max_spawn_height),
			randf_range(-spawn_radius, spawn_radius)
		)
	
	var enemy = enemy_scene.instantiate()
	
	if enemy.has_method("set_lifetime"):
		enemy.set_lifetime(enemy_lifetime)
	
	add_child(enemy)
	enemy.global_position = spawn_position
	enemies.append(enemy)

func cleanup_enemies():
	var valid_enemies = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_inside_tree():
			valid_enemies.append(enemy)
		elif is_instance_valid(enemy):
			enemy.queue_free()
	
	enemies = valid_enemies

func clear_all_enemies():
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()

func deactivate_spawner():
	is_active = false
	clear_all_enemies()

func activate_spawner():
	is_active = true

func set_enabled(value: bool):
	enabled = value
	if not value:
		clear_all_enemies()

func get_enemy_count() -> int:
	return enemies.size()