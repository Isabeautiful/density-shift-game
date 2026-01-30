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
#Hud
@onready var label_feedback: Label = $CameraPivot/CameraController/Camera3D/CanvasLayer/PlayerFeedback/LabelFeedback
@onready var label: Label = $CameraPivot/CameraController/Camera3D/CanvasLayer/Dialog/Label
@onready var button: Button = $CameraPivot/CameraController/Camera3D/CanvasLayer/Dialog/Button
@onready var dialog: Control = $CameraPivot/CameraController/Camera3D/CanvasLayer/Dialog
@export var typing_speed : float = 0.01
@export var pause_game : bool = true

var expected_input:String
var is_typing = false
var is_dialog_active = true
var actual_message : String
signal button_pressed()
# Getter para uso nos estados
var is_grounded: bool:
	get: return is_on_floor()

var kinetic_energy: float:
	get: return (current_mass * (velocity.y*velocity.y))/2

func _ready():
	add_to_group("player")  # ADICIONE ESTA LINHA
	print("Player: Adicionado ao grupo 'player'")
	
	mao_start_posY = mao_r.position.y
	print("mao start: ",mao_start_posY)
	# Inicializa a máquina de estados
	print("Player inicializando...")
	state_machine.init(self)
	current_mass = mass_light
	print("Player pronto")
	
	# DEBUG: Mostrar informações de colisão
	print("Player - collision_layer: ", collision_layer)
	print("Player - collision_mask: ", collision_mask)

func _physics_process(delta):
	dialog.visible = is_dialog_active
	if expected_input != "":
		if Input.is_action_just_pressed(expected_input):
			hide_dialog(false)
		
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

func set_dialog_text(texto : String):
	is_dialog_active = true
	actual_message = texto
	await type_text(texto, label)
	
func set_feedback_text(texto: String):
	label_feedback.visible = true
	await type_text(texto, label_feedback)
	await get_tree().create_timer(3.0).timeout
	label_feedback.visible = false
	
func type_text(text:String, selected_label):
	is_typing = true
	selected_label.text = ""
	
	for i in range(text.length()):
		if selected_label.text != actual_message:
			selected_label.text += text[i]
			await get_tree().create_timer(typing_speed).timeout
	
	is_typing =false

func hide_dialog(by_btn:bool):
	if !by_btn:
		is_dialog_active = false
		expected_input = ""

	if is_typing:
		label.text = actual_message
		is_typing = false
	else:
		is_dialog_active = false
	
func hide_dialog_by_input(input: String=""):
	expected_input = input

func show_btn(visibility:bool):
	button.visible = visibility
	
func _on_button_pressed() -> void:
	button_pressed.emit()
	hide_dialog(true)
