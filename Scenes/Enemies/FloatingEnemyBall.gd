extends Area3D

@export var speed: float = 5.0
@export var rotation_speed: float = 2.0
@export var detection_range: float = 25.0
@export var damage: int = 1
@export var bob_speed: float = 2.0
@export var bob_height: float = 0.2
@export var player_search_interval: float = 0.5
@export var lifetime: float = 60.0
@export var despawn_distance: float = 50.0
@export var min_flight_height: float = 8.0  # Altura mínima de voo

var player: CharacterBody3D = null
var time: float = 0.0
var is_active: bool = true
var chase_player: bool = false
var player_search_timer: float = 0.0
var life_timer: float = 0.0

func _ready():
	find_player()
	body_entered.connect(_on_body_entered)
	
	# Garantir que está acima do chão
	if global_position.y < min_flight_height:
		global_position.y = min_flight_height
	
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
	
	# Despawn após 60 segundos
	if life_timer >= lifetime:
		queue_free()
		return
	
	# Buscar jogador periodicamente
	if player_search_timer >= player_search_interval:
		find_player()
		player_search_timer = 0.0
	
	if player == null:
		return
	
	# Despawn se muito longe do jogador
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > despawn_distance:
		queue_free()
		return
	
	# Rotação constante
	rotate_y(rotation_speed * delta)
	
	# Movimento de flutuação
	var bob_offset = sin(time * bob_speed) * bob_height * delta * 10
	global_position.y += bob_offset
	
	# Seguir jogador se estiver dentro do alcance
	if distance_to_player <= detection_range:
		chase_player = true
		
		# Calcular direção 3D para o jogador
		var direction = (player.global_position - global_position).normalized()
		
		# Mover em direção ao jogador (3D)
		global_position += direction * speed * delta
		
		# Olhar para o jogador
		look_at(player.global_position, Vector3.UP)
		
		# Ajustar cor baseado na distância (opcional)
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
	
	# Verificar se colidiu com o jogador
	if body.is_in_group("player"):
		is_active = false
		
		# Aplicar dano ao jogador (com delay para efeitos visuais)
		await get_tree().create_timer(0.2).timeout
		apply_damage_to_player()

func apply_damage_to_player():
	# Tentar chamar função de dano no jogador
	if player and player.has_method("take_damage"):
		player.take_damage(damage)
	else:
		# Fallback: recarregar a cena
		get_tree().reload_current_scene()

func deactivate():
	# Desativar a bola
	is_active = false
	if has_node("Particles"):
		$Particles.emitting = false
	if has_node("Light"):
		$Light.light_energy = 0.0

func set_lifetime(new_lifetime: float):
	lifetime = new_lifetime
