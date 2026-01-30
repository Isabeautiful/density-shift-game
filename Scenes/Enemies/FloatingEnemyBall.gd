extends Area3D

@export var speed: float = 5.0
@export var rotation_speed: float = 2.0
@export var detection_range: float = 25.0
@export var damage: int = 1
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.2
@export var player_search_interval: float = 0.5
@export var lifetime: float = 30.0
@export var despawn_distance: float = 50.0

var player: CharacterBody3D = null
var original_y: float = 0.0
var time: float = 0.0
var is_active: bool = true
var chase_player: bool = false
var player_search_timer: float = 0.0
var life_timer: float = 0.0

func _ready():
	find_player()
	original_y = global_position.y
	body_entered.connect(_on_body_entered)
	if has_node("Particles"):
		$Particles.emitting = true
	if has_node("Light"):
		$Light.light_energy = 2.0

func _physics_process(delta):
	if not is_active:
		return
	
	time += delta
	player_search_timer += delta
	life_timer += delta
	
	if life_timer >= lifetime:
		queue_free()
		return
	
	if player_search_timer >= player_search_interval:
		find_player()
		player_search_timer = 0.0
	
	if player == null:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > despawn_distance:
		queue_free()
		return
	
	var bob_offset = sin(time * bob_speed) * bob_height
	global_position.y = original_y + bob_offset
	
	rotate_y(rotation_speed * delta)
	
	if distance_to_player <= detection_range:
		chase_player = true
		var player_pos_flat = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		var direction = (player_pos_flat - global_position).normalized()
		global_position += direction * speed * delta
		look_at(player.global_position, Vector3.UP)
		
		if has_node("MeshInstance3D"):
			var mesh = $MeshInstance3D
			if mesh.material_override:
				var intensity = clamp(1.0 - (distance_to_player / detection_range), 0.3, 1.0)
				mesh.material_override.emission = Color(1.0, 0.1, 0.1, intensity * 0.8)
	else:
		chase_player = false

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _on_body_entered(body):
	if not is_active:
		return
	
	if body.is_in_group("player"):
		is_active = false
		await get_tree().create_timer(0.2).timeout
		apply_damage_to_player()

func apply_damage_to_player():
	if player and player.has_method("take_damage"):
		player.take_damage(damage)
	else:
		get_tree().reload_current_scene()

func deactivate():
	is_active = false
	if has_node("Particles"):
		$Particles.emitting = false
	if has_node("Light"):
		$Light.light_energy = 0.0
