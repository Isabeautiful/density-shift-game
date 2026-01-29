extends CharacterBody3D

@export var gravity_scale: float = 1.0
@export var jump_velocity: float = 10.0
@export var move_speed: float = 5.0

# Propriedades para diferentes estados
@export var mass_light: float = 1.0
@export var mass_heavy: float = 3.0

@onready var mao_r: Node3D = $CameraPivot/CameraController/Camera3D/mao_r
@onready var mao_e: Node3D = $CameraPivot/CameraController/Camera3D/mao_e

var current_mass: float = 1.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var air_kinetic_energy : float
@onready var state_machine = $StateMachine
@onready var camera_pivot = $CameraPivot

var mao_start_posY : int

# Getter para uso nos estados
var is_grounded: bool:
	get: return is_on_floor()

var kinetic_energy: float:
	get: return (current_mass * (velocity.y*velocity.y))/2

func _ready():
	mao_start_posY = mao_r.position.y
	print("mao start: ",mao_start_posY)
	# Inicializa a máquina de estados
	print("Player inicializando...")
	state_machine.init(self)
	current_mass = mass_light
	print("Player pronto")

func _physics_process(delta):
	# Aplica gravidade considerando a massa
	if not is_on_floor():
		velocity.y -= gravity * gravity_scale * delta
		air_kinetic_energy = kinetic_energy
		
	elif Input.is_action_pressed("move_back") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		shake_hands(delta)
	# Delega o processamento de física para a máquina de estados
	state_machine.process_physics(delta)
	move_and_slide()
	


	
	# Verificar se caiu do mapa
	if global_position.y < -10:
		respawn()

var shake_timer = 0.0
var shake_speed = 5.0  
func shake_hands(delta):
	shake_timer += delta * shake_speed
	var offset_r = sin(shake_timer) * 0.005 
	var offset_e = cos(shake_timer) * 0.005 
	
	mao_r.position.y += mao_start_posY/2 + offset_r
	mao_e.position.y += mao_start_posY/2 + offset_e
	
func _input(event):
	# Delega o processamento de input para a máquina de estados
	state_machine.process_input(event)

func get_move_direction() -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_back", "move_foward")
	#print("Input: ", input_dir)  # Debug
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func can_jump() -> bool:
	return is_on_floor()

func set_mass(new_mass: float) -> void:
	current_mass = new_mass

func respawn():
	# Reposicionar o jogador no início, mas não muito alto para não bater no teto
	global_position = Vector3(0, 2, 0)  # Mais baixo que antes
	velocity = Vector3.ZERO
	print("Player respawned!")
