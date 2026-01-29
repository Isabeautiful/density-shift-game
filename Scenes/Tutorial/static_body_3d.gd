extends Node3D
@export var size_floor : int = 200
@export var size_wall : int = 300

@onready var floor: StaticBody3D = $chao
@onready var wall_1: StaticBody3D = $"Parede1"
@onready var wall_2: StaticBody3D = $"Parede2"
@onready var wall_3: StaticBody3D = $"Parede3"
@onready var wall_4: StaticBody3D = $"Parede4"

var elementos = [floor,wall_1,wall_2,wall_3,wall_4]
var conf_mesh_chao = Vector3(size_floor,0.1,size_floor)
var conf_parede = Vector3(size_wall,size_wall,0.1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gerar_limites()
	textura(floor.get_node("MeshInstance3D"))
	
func textura(mesh_i):
	var material = StandardMaterial3D.new()
	var textura = load("res://assets/textures/CleanEdge_tileset.png")
	material.albedo_texture = textura
	mesh_i.material_override = material
	
func alinha_hitbox(mesh_i, collision_i)->void:
	if mesh_i is BoxMesh:
		var box_mesh = mesh_i.mesh as BoxMesh
		
		var mesh_size = box_mesh.size
		var mesh_rot = box_mesh.rotation_degrees
		var box_shape = BoxShape3D.new()
		
		box_shape.size = mesh_size
		box_shape.transform.rotation = mesh_rot
		collision_i.shape = box_shape
		collision_i.transform.rotation = mesh_rot
		
func gerar_limites() -> void:
	var elementos = [floor, wall_1, wall_2, wall_3, wall_4]
	
	if floor != null and floor.has_node("MeshInstance3D"):
		var floor_mesh = floor.get_node("MeshInstance3D").mesh
		if floor_mesh is BoxMesh:
			floor_mesh.size = conf_mesh_chao
		
		var floor_collision = floor.get_node("CollisionShape3D")
		alinha_hitbox(floor.get_node("MeshInstance3D"), floor_collision)
	
	for i in range(1, len(elementos)):  # Começa em 1 (pula floor)
		if elementos[i] == null:
			push_error("elementos[%d] é null!" % i)
			continue
		var mesh_instance = elementos[i].get_node_or_null("MeshInstance3D")
		var collision = elementos[i].get_node_or_null("CollisionShape3D")

		alinha_hitbox(mesh_instance, collision)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
