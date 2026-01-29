extends State

class_name LightState

var jump_count: int = 0
var max_jumps: int = 2
var jump_velocity: float = 15.0
var move_speed: float = 8.0
var acceleration: float = 20.0
var deceleration: float = 15.0

func enter() -> void:
	print("LightState: Entrou no estado LEVE")
	player.set_feedback_text("Entrou no modo leve")
	# Configura propriedades físicas
	player.set_mass(player.mass_light)
	player.gravity_scale = 0.7
	
	# Reset contador de pulos
	jump_count = 0

func exit() -> void:
	print("LightState: Saindo do estado")

func process_physics(delta: float) -> void:
	var direction = player.get_move_direction()
	
	# Aplica movimento
	if direction:
		player.velocity.x = lerp(player.velocity.x, direction.x * move_speed, acceleration * delta)
		player.velocity.z = lerp(player.velocity.z, direction.z * move_speed, acceleration * delta)
		#print("LightState: Movendo - Velocidade: ", player.velocity)
	else:
		player.velocity.x = lerp(player.velocity.x, 0.0, deceleration * delta)
		player.velocity.z = lerp(player.velocity.z, 0.0, deceleration * delta)
	
	# Pulo
	if Input.is_action_just_pressed("jump"):
		if player.can_jump() or jump_count < max_jumps:
			player.velocity.y = jump_velocity
			jump_count += 1
	
	# Verifica se está no chão para resetar contador de pulos
	if player.is_grounded:
		jump_count = 0

func process_input(event: InputEvent, player:CharacterBody3D) -> void:
	if event.is_action_pressed("toggle_heavy"):
		print("LightState: Solicitando mudança para HeavyState")
		transitioned.emit(self, "HeavyState")
