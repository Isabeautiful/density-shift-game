extends CharacterBody3D

@export var gravity_scale: float = 1.0
@export var jump_velocity: float = 10.0
@export var move_speed: float = 5.0
@export var mass_light: float = 1.0
@export var mass_heavy: float = 5.0

@onready var mao_r: Node3D = $CameraPivot/CameraController/Camera3D/mao_r
@onready var mao_e: Node3D = $CameraPivot/CameraController/Camera3D/mao_e
@onready var state_machine = $StateMachine
@onready var camera_pivot = $CameraPivot

@onready var panel: Panel = $CameraPivot/CameraController/Camera3D/CanvasLayer/Dialog/Panel
@onready var label_feedback: Label = $CameraPivot/CameraController/Camera3D/CanvasLayer/PlayerFeedback/LabelFeedback
@onready var label: RichTextLabel = $CameraPivot/CameraController/Camera3D/CanvasLayer/Dialog/Label
@onready var button: Button = $CameraPivot/CameraController/Camera3D/CanvasLayer/Dialog/Button
@onready var dialog: Control = $CameraPivot/CameraController/Camera3D/CanvasLayer/Dialog
@export var typing_speed : float = 0.01
@export var pause_game : bool = true

@onready var value_hp: Label = $CameraPivot/CameraController/Camera3D/CanvasLayer/HP_container/HBoxContainer/value_hp

var current_mass: float = 1.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var air_kinetic_energy : float
var mao_start_posY : int
var expected_input:String
var is_typing = false
var is_dialog_active = false
var actual_message : String
var hp = 3
var actual_state : String = "Modo Pesado"

signal button_pressed()

var is_grounded: bool:
	get: return is_on_floor()

var kinetic_energy: float:
	get: return (current_mass * ((velocity.y*velocity.y) + (velocity.x*velocity.x)))/2

var typing : bool:
	get: return is_typing
	
func _ready():
	add_to_group("player")
	mao_start_posY = mao_r.position.y
	state_machine.init(self)
	current_mass = mass_light

func _physics_process(delta):
	dialog.visible = is_dialog_active
	panel.visible = is_dialog_active
	label.visible = is_dialog_active
	label_feedback.visible = true
	
	value_hp.text = str(hp)
	
	if expected_input != "":
		if Input.is_action_just_pressed(expected_input):
			hide_dialog(false)
		
	if not is_on_floor():
		velocity.y -= gravity * gravity_scale * delta
		air_kinetic_energy = kinetic_energy
		
	elif Input.is_action_pressed("move_back") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		shake_hands(delta)
		
	state_machine.process_physics(delta)
	move_and_slide()
	
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
	state_machine.process_input(event,self)

func get_move_direction() -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_back", "move_foward")
	return (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

func set_move_speed(val:float):
	move_speed = val

func can_jump() -> bool:
	return is_on_floor()

func set_mass(new_mass: float) -> void:
	current_mass = new_mass

func respawn():
	take_damage()
	global_position = Vector3(0, 2, 0)
	velocity = Vector3.ZERO

func show_message(text:String, show_btn:bool, action:String):
	if not typing:
		set_dialog_text(text)
		show_btn(show_btn)
		hide_dialog_by_input(action)
		
func set_dialog_text(texto : String):
	is_dialog_active = true
	actual_message = texto
	label.text = ""
	
	is_typing = true
	await type_text(texto, label)
	is_typing = false
	
func set_feedback_text(texto: String):
	label_feedback.visible = true
	await type_text(texto, label_feedback)
	await get_tree().create_timer(3.0).timeout

func type_text(text:String, selected_label):
	selected_label.text = ""
	for i in range(text.length()):
		selected_label.text += text[i]
		await get_tree().create_timer(typing_speed).timeout
	

func hide_dialog(by_btn:bool):
	if is_typing:
		if !by_btn:
			is_dialog_active = false
			expected_input = ""
			
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

func detect_collision(group,action:Callable) -> void:
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = from - Vector3(0, 1.5, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)
	
	if result:
		var collider = result.collider
		if collider.is_in_group(group):
			action.call()
			
func take_damage(amount: int = 1):
	hp -= amount
	if(hp <=0):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://Scenes/Control/Defeat/Defeat.tscn")
		
