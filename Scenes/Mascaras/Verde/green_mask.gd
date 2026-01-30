extends StaticBody3D
@onready var mesh_instance_3d: MeshInstance3D = $"../MeshInstance3D"
@onready var collision_shape_3d: CollisionShape3D = $"."

signal collision()

func _ready() -> void:
	add_to_group("GreenM")
	mesh_instance_3d.add_to_group("GreenM")
	collision_shape_3d.add_to_group("GreenM")
	

func _process(delta: float) -> void:
	pass
