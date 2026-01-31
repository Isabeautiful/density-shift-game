extends StaticBody3D

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

enum FloorType {rigid_floor, fragile_floor}
@export var Floor_type : FloorType = FloorType.rigid_floor
var break_force: float = 350.0

signal fragile_floor_broke();

func set_break_force(val:float):
	break_force = val

func _ready() -> void:
	var type = ""
	if Floor_type == FloorType.rigid_floor:
		type = "rigid_floor"
	else:
		type = "fragile_floor"
		
	self.add_to_group(type)
	collision_shape_3d.add_to_group(type)
	mesh_instance_3d.add_to_group(type)

func set_stats(pos:Vector3):
	set_position(pos)
	
func break_self() -> void:
	print("Piso frágil quebrado!")
	queue_free()
	fragile_floor_broke.emit()
	# Cooldown para próxima quebra
	await get_tree().create_timer(0.5).timeout
