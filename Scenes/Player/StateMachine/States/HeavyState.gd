extends State

class_name HeavyState

var jump_count: int = 0
var max_jumps: int = 1  # Apenas 1 pulo no estado pesado
var jump_velocity: float = 4.0
var move_speed: float = 14.0
var acceleration: float = 15.0
var deceleration: float = 15.0
#var break_force: float = 500.0
var can_break: bool = true

func enter() -> void:
	print("HeavyState: Entrou no estado PESADO")
	player.set_feedback_text("Modo Pesado")

	# Configura propriedades físicas
	player.set_mass(player.mass_heavy)
	player.gravity_scale = 5
	
	# Reset contador de pulos
	jump_count = 0
	
	can_break = true

func exit() -> void:
	print("HeavyState: Saindo do estado")

func process_physics(delta: float) -> void:
	var direction = player.get_move_direction()
	
	# Aplica movimento (mais lento no estado pesado)
	if direction:
		player.velocity.x = lerp(player.velocity.x, direction.x * move_speed, acceleration * delta)
		player.velocity.z = lerp(player.velocity.z, direction.z * move_speed, acceleration * delta)
		#awddprint("HeavyState: Movendo - Velocidade: ", player.velocity)
	else:
		player.velocity.x = lerp(player.velocity.x, 0.0, deceleration * delta)
		player.velocity.z = lerp(player.velocity.z, 0.0, deceleration * delta)
	
	# Pulo (mais fraco e apenas 1 pulo)
	if Input.is_action_just_pressed("jump"):
		if player.can_jump() or jump_count < max_jumps:
			player.velocity.y = jump_velocity
			jump_count += 1
	
	# Verifica se está no chão para resetar contador de pulos
	if player.is_grounded:
		jump_count = 0
	
	# Verifica quebra de pisos frágeis (apenas se estiver no chão)
	if player.is_grounded and can_break:
		check_fragile_floors()

func process_input(event: InputEvent, player: CharacterBody3D) -> void:
	if event.is_action_pressed("toggle_light"):
		print("HeavyState: Solicitando mudança para LightState")
		transitioned.emit(self, "LightState")
		
	# Ação de quebrar pisos (pode ser ativada manualmente também)
	if event.is_action_pressed("break_floor"):
		break_fragile_floor()

func check_fragile_floors() -> void:
	# Raycast para verificar se está sobre piso frágil
	var space_state = player.get_world_3d().direct_space_state
	var from = player.global_position
	var to = from - Vector3(0, 2.0, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	
	var is_breaking = Input.is_action_pressed("break_floor")
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider.is_in_group("fragile_floor"):
			if abs(player.air_kinetic_energy) > collider.break_force and is_breaking:
				break_floor(collider)

func break_floor(floor_node: Node) -> void:
	print("node: ", floor_node)
	if can_break:
		print("Piso frágil quebrado!")
		can_break = false
		floor_node.break_self()
		# Cooldown para próxima quebra
		await get_tree().create_timer(0.5).timeout
		can_break = true

func break_fragile_floor() -> void:
	if not can_break:
		return
	
	# Quebra piso diretamente abaixo do jogador
	var space_state = player.get_world_3d().direct_space_state
	var from = player.global_position
	var to = from - Vector3(0, 1.5, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	
	var is_breaking = Input.is_action_pressed("break_floor")
	var result = space_state.intersect_ray(query)
	if result:
		var collider = result.collider
		if collider.is_in_group("fragile_floor"):
			if abs(player.air_kinetic_energy) > collider.break_force and is_breaking:
				break_floor(collider)
