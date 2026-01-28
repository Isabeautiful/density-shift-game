extends CharacterBody3D

@export var gravity_scale: float = 1.0
@export var jump_velocity: float = 10.0
@export var move_speed: float = 5.0

# Propriedades para diferentes estados
@export var mass_light: float = 1.0
@export var mass_heavy: float = 3.0

var current_mass: float = 1.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var air_kinetic_energy : float
@onready var state_machine = $StateMachine
@onready var camera_pivot = $CameraPivot

# Getter para uso nos estados
var is_grounded: bool:
	get: return is_on_floor()

var kinetic_energy: float:
	get: return (current_mass * (velocity.y*velocity.y))/2

func _ready():
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
	#print("Energia cinetica: ",air_kinetic_energy)
	# Delega o processamento de física para a máquina de estados
	state_machine.process_physics(delta)
	move_and_slide()

	# Verificar se caiu do mapa
	if global_position.y < -10:
		respawn()


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
