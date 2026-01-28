extends Node3D

@export var floor_size: float = 100
@export var maze_cell_size: float = 10
@export var wall_height: float = 45
@export var ceiling_height: float = 45
@export var complexity: float = 0.3
@export var fragile_floor_chance: float = 0.2

@onready var wall_scene = preload("res://Scenes/TowerFloor/Wall.tscn")
@onready var fragile_floor_scene = preload("res://Scenes/Floor/floor.tscn")

func _ready():
	generate_tower_floor()
	add_external_walls()
	generate_maze()
	generate_floating_floors()

func generate_tower_floor():
	$MainFloor.transform.origin = Vector3(0, 0, 0)
	$Ceiling.transform.origin = Vector3(0, ceiling_height, 0)

func add_external_walls():
	var half_size = floor_size / 2.0
	
	# Norte
	create_wall(Vector3(0, wall_height/2, -half_size), Vector3(floor_size, wall_height, 0.5))
	# Sul
	create_wall(Vector3(0, wall_height/2, half_size), Vector3(floor_size, wall_height, 0.5))
	# Leste
	create_wall(Vector3(-half_size, wall_height/2, 0), Vector3(0.5, wall_height, floor_size))
	# Oeste
	create_wall(Vector3(half_size, wall_height/2, 0), Vector3(0.5, wall_height, floor_size))

func generate_maze():
	var cells_x = int(floor_size / maze_cell_size)
	var cells_z = int(floor_size / maze_cell_size)
	
	var maze = []
	for x in range(cells_x):
		maze.append([])
		for z in range(cells_z):
			var is_wall = x == 0 or x == cells_x-1 or z == 0 or z == cells_z-1 or randf() < complexity
			maze[x].append(1 if is_wall else 0)
	
	create_main_paths(maze)
	
	for x in range(cells_x):
		for z in range(cells_z):
			if maze[x][z] == 1:
				var pos_x = (x * maze_cell_size) - (floor_size / 2) + (maze_cell_size / 2)
				var pos_z = (z * maze_cell_size) - (floor_size / 2) + (maze_cell_size / 2)
				create_wall(Vector3(pos_x, wall_height/2, pos_z), Vector3(maze_cell_size, wall_height, 0.2))

func create_main_paths(maze):
	var cells_x = maze.size()
	var cells_z = maze[0].size()
	
	var middle_z = int(cells_z / 2)
	for x in range(2, cells_x - 2):
		maze[x][middle_z] = 0
		if x % 6 == 0 and middle_z > 2 and middle_z < cells_z - 3:
			for offset in range(-2, 3):
				maze[x][middle_z + offset] = 0
	
	var middle_x = int(cells_x / 2)
	for z in range(2, cells_z - 2):
		maze[middle_x][z] = 0
		if z % 8 == 0 and middle_x > 2 and middle_x < cells_x - 3:
			for offset in range(-2, 3):
				maze[middle_x + offset][z] = 0
	
	maze[2][2] = 0
	maze[cells_x - 3][cells_z - 3] = 0

func create_wall(position: Vector3, size: Vector3):
	var wall = wall_scene.instantiate()
	wall.transform.origin = position
	
	var collision_shape = wall.get_node("CollisionShape3D")
	var mesh_instance = wall.get_node("MeshInstance3D")
	
	if collision_shape and collision_shape.shape is BoxShape3D:
		collision_shape.shape.size = size
	
	if mesh_instance and mesh_instance.mesh is BoxMesh:
		mesh_instance.mesh.size = size
	
	$MazeWalls.add_child(wall)

func generate_floating_floors():
	var num_floors = int((floor_size * floor_size) / 400)
	
	for i in range(num_floors):
		var pos_x = randf_range(-floor_size/2 + 5, floor_size/2 - 5)
		var pos_z = randf_range(-floor_size/2 + 5, floor_size/2 - 5)
		var height = randf_range(1, wall_height - 5)
		
		var floor_instance = fragile_floor_scene.instantiate()
		floor_instance.transform.origin = Vector3(pos_x, height, pos_z)
		
		var mesh_instance = floor_instance.get_node("MeshInstance3D")
		var collision_shape = floor_instance.get_node("CollisionShape3D")
		
		if mesh_instance and mesh_instance.mesh is PlaneMesh:
			var mesh_size = Vector2(randf_range(3, 8), randf_range(3, 8))
			mesh_instance.mesh.size = mesh_size
		
		if collision_shape and collision_shape.shape is BoxShape3D:
			collision_shape.shape.size = Vector3(
				randf_range(3, 8), 
				0.1, 
				randf_range(3, 8)
			)
		
		if randf() < fragile_floor_chance:
			floor_instance.Floor_type = 1
		else:
			floor_instance.Floor_type = 0
		
		$FloatingFloors.add_child(floor_instance)
