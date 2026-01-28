extends Node3D

@export var floor_size: float = 100
@export var maze_cell_size: float = 10
@export var wall_height: float = 45
@export var ceiling_height: float = 45
@export var fragile_floor_chance: float = 0.2
@export var num_floors: int = 3  # Número de andares
@export var floor_spacing: float = 10  # Espaço entre andares

@onready var wall_scene = preload("res://Scenes/TowerFloor/Wall.tscn")
@onready var fragile_floor_scene = preload("res://Scenes/Floor/floor.tscn")

var maze = []  # Matriz do labirinto

func _ready():
	generate_tower_floor()
	generate_maze()
	create_floors_from_maze()
	add_external_walls()

func generate_tower_floor():
	$MainFloor.transform.origin = Vector3(0, 0, 0)
	$Ceiling.transform.origin = Vector3(0, ceiling_height, 0)

func generate_maze():
	var grid_width = int(floor_size / maze_cell_size)
	var grid_height = int(floor_size / maze_cell_size)
	
	# Cria uma matriz para o labirinto (true = parede, false = caminho)
	maze = []
	for x in range(grid_width):
		maze.append([])
		for y in range(grid_height):
			maze[x].append(true)  # Começa com todas as células como paredes
	
	# Algoritmo de Recursive Backtracker (DFS)
	var stack = []
	var start_x = 1
	var start_y = 1
	
	maze[start_x][start_y] = false  # Célula inicial como caminho
	stack.append(Vector2(start_x, start_y))
	
	var directions = [
		Vector2(0, -2),  # Norte
		Vector2(0, 2),   # Sul
		Vector2(-2, 0),  # Oeste
		Vector2(2, 0)    # Leste
	]
	
	while stack.size() > 0:
		var current = stack.back()
		var x = int(current.x)
		var y = int(current.y)
		
		# Verifica vizinhos não visitados
		var neighbors = []
		
		for dir in directions:
			var nx = x + int(dir.x)
			var ny = y + int(dir.y)
			
			if nx > 0 and nx < grid_width-1 and ny > 0 and ny < grid_height-1:
				if maze[nx][ny]:  # Se ainda não foi visitado (é parede)
					neighbors.append(Vector2(nx, ny))
		
		if neighbors.size() > 0:
			# Escolhe um vizinho aleatório
			var next = neighbors[randi() % neighbors.size()]
			var nx = int(next.x)
			var ny = int(next.y)
			
			# Remove a parede entre a célula atual e o vizinho
			var mid_x = (x + nx) / 2
			var mid_y = (y + ny) / 2
			
			maze[mid_x][mid_y] = false  # Cria passagem
			maze[nx][ny] = false  # Marca nova célula como caminho
			
			stack.append(Vector2(nx, ny))
		else:
			stack.pop_back()
	
	# Cria entrada e saída
	maze[1][0] = false  # Entrada
	maze[grid_width-2][grid_height-1] = false  # Saída
	
	# Cria as paredes físicas baseadas na matriz do labirinto
	create_walls_from_maze()

func create_walls_from_maze():
	var grid_width = maze.size()
	var grid_height = maze[0].size()
	
	# Cria todas as paredes horizontais
	for x in range(grid_width-1):
		for y in range(grid_height):
			# Verifica se precisa de parede entre célula[x][y] e célula[x][y+1]
			if y < grid_height - 1:
				if maze[x][y] or maze[x][y+1] or (maze[x][y] != maze[x][y+1]):
					# Parede horizontal entre células
					var pos_x = (x * maze_cell_size) - (floor_size / 2) + (maze_cell_size / 2)
					var pos_z = (y * maze_cell_size) - (floor_size / 2) + maze_cell_size
					
					create_wall(
						Vector3(pos_x, wall_height/2, pos_z),
						Vector3(maze_cell_size, wall_height, 0.2)
					)
	
	# Cria todas as paredes verticais
	for x in range(grid_width):
		for y in range(grid_height-1):
			# Verifica se precisa de parede entre célula[x][y] e célula[x+1][y]
			if x < grid_width - 1:
				if maze[x][y] or maze[x+1][y] or (maze[x][y] != maze[x+1][y]):
					# Parede vertical entre células
					var pos_x = (x * maze_cell_size) - (floor_size / 2) + maze_cell_size
					var pos_z = (y * maze_cell_size) - (floor_size / 2) + (maze_cell_size / 2)
					
					create_wall(
						Vector3(pos_x, wall_height/2, pos_z),
						Vector3(0.2, wall_height, maze_cell_size)
					)

func create_floors_from_maze():
	var grid_width = maze.size()
	var grid_height = maze[0].size()
	
	# Para cada andar
	for floor_level in range(num_floors):
		var floor_height = 1 + (floor_level * floor_spacing)
		
		# Para cada célula do labirinto
		for x in range(grid_width):
			for y in range(grid_height):
				# Se não for parede (é caminho)
				if not maze[x][y]:
					# Calcula a posição do piso (centro da célula)
					var pos_x = (x * maze_cell_size) - (floor_size / 2) + (maze_cell_size / 2)
					var pos_z = (y * maze_cell_size) - (floor_size / 2) + (maze_cell_size / 2)
					
					# Cria o piso para esta célula
					create_floor_cell(pos_x, floor_height, pos_z, floor_level)

func create_floor_cell(x, y, z, floor_level):
	var floor_instance = fragile_floor_scene.instantiate()
	floor_instance.transform.origin = Vector3(x, y, z)
	
	var mesh_instance = floor_instance.get_node("MeshInstance3D")
	var collision_shape = floor_instance.get_node("CollisionShape3D")
	
	# Tamanho do piso (ligeiramente menor que a célula para não tocar nas paredes)
	var floor_size_x = maze_cell_size - 0.2
	var floor_size_z = maze_cell_size - 0.2
	var floor_thickness = 0.3
	
	# Ajustar o mesh
	if mesh_instance:
		var new_mesh = BoxMesh.new()
		new_mesh.size = Vector3(floor_size_x, floor_thickness, floor_size_z)
		mesh_instance.mesh = new_mesh
	
	# Ajustar a colisão
	if collision_shape:
		var new_shape = BoxShape3D.new()
		new_shape.size = Vector3(floor_size_x, floor_thickness, floor_size_z)
		collision_shape.shape = new_shape
	
	# Decidir se é piso frágil ou não
	# Andares mais altos têm maior chance de serem frágeis
	var fragile_chance = fragile_floor_chance + (floor_level * 0.1)
	
	if randf() < fragile_chance:
		floor_instance.Floor_type = 1
		# Material vermelho para pisos frágeis
		var material = StandardMaterial3D.new()
		# Tons diferentes para diferentes andares
		var shade = 0.7 - (floor_level * 0.1)
		material.albedo_color = Color(shade, 0.3, 0.3)
		material.roughness = 0.7
		mesh_instance.material_override = material
	else:
		floor_instance.Floor_type = 0
		# Material cinza para pisos sólidos
		var material = StandardMaterial3D.new()
		# Tons diferentes para diferentes andares
		var shade = 0.8 - (floor_level * 0.15)
		material.albedo_color = Color(shade, shade, shade)
		material.roughness = 0.8
		mesh_instance.material_override = material
	
	$FloatingFloors.add_child(floor_instance)

func add_external_walls():
	var half_size = floor_size / 2.0
	
	# Paredes externas (bordas do labirinto)
	# Norte
	create_wall(
		Vector3(0, wall_height/2, -half_size),
		Vector3(floor_size, wall_height, 0.5)
	)
	# Sul
	create_wall(
		Vector3(0, wall_height/2, half_size),
		Vector3(floor_size, wall_height, 0.5)
	)
	# Leste
	create_wall(
		Vector3(-half_size, wall_height/2, 0),
		Vector3(0.5, wall_height, floor_size)
	)
	# Oeste
	create_wall(
		Vector3(half_size, wall_height/2, 0),
		Vector3(0.5, wall_height, floor_size)
	)

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