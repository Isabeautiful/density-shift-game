# CameraController.gd
extends Node3D

@export var mouse_sensitivity: float = 0.002
@export var min_pitch: float = -90.0
@export var max_pitch: float = 90.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		# Rotação horizontal (player)
		get_parent().get_parent().rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotação vertical (câmera)
		var new_pitch = rotation.x - event.relative.y * mouse_sensitivity
		rotation.x = clamp(new_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
	
	if Input.is_action_just_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
