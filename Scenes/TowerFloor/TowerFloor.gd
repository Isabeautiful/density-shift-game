extends Node3D

@export var floor_size: float = 100
@export var maze_cell_size: float = 10
@export var wall_height: float = 45
@export var ceiling_height: float = 45
@export var fragile_floor_chance: float = 0.2

@onready var wall_scene = preload("res://Scenes/TowerFloor/Wall.tscn")
@onready var fragile_floor_scene = preload("res://Scenes/Floor/floor.tscn")

func _ready():
	generate_tower_floor()
	generate_maze()
	add_external_walls()
	generate_floating_floors()

func generate_tower_floor():
	$MainFloor.transform.origin = Vector3(0, 0, 0)
	$Ceiling.transform.origin = Vector3(0, ceiling_height, 0)

func generate_maze():
	var grid_width = int(floor_size / maze_cell_size)
	var grid_height = int(floor_size / maze_cell_size)
	
	# Cria uma matriz para o labirinto (true = parede, false = caminho)
	var maze = []
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
	create_walls_from_maze(maze, grid_width, grid_height)

func create_walls_from_maze(maze, width, height):
	# Primeiro, cria paredes horizontais
	for x in range(width-1):
		for y in range(height):
			# Se a célula atual é parede OU se há parede abaixo
			if maze[x][y] or (y < height-1 and (maze[x][y+1] or maze[x][y])):
				# Verifica se precisa de parede horizontal
				var needs_horizontal_wall = false
				
				if y == 0 or y == height-1:
					# Bordas sempre têm paredes
					needs_horizontal_wall = true
				elif maze[x][y] != maze[x][y-1]:
					# Transição entre caminho e parede
					needs_horizontal_wall = true
				
				if needs_horizontal_wall:
					var pos_x = (x * maze_cell_size) - (floor_size / 2) + (maze_cell_size / 2)
					var pos_z = (y * maze_cell_size) - (floor_size / 2)
					
					# Paredes horizontais
					create_wall(
						Vector3(pos_x, wall_height/2, pos_z),
						Vector3(maze_cell_size, wall_height, 0.2)
					)
	
	# Agora, cria paredes verticais
	for x in range(width):
		for y in range(height-1):
			# Se a célula atual é parede OU se há parede à direita
			if maze[x][y] or (x < width-1 and (maze[x+1][y] or maze[x][y])):
				# Verifica se precisa de parede vertical
				var needs_vertical_wall = false
				
				if x == 0 or x == width-1:
					# Bordas sempre têm paredes
					needs_vertical_wall = true
				elif maze[x][y] != maze[x-1][y]:
					# Transição entre caminho e parede
					needs_vertical_wall = true
				
				if needs_vertical_wall:
					var pos_x = (x * maze_cell_size) - (floor_size / 2)
					var pos_z = (y * maze_cell_size) - (floor_size / 2) + (maze_cell_size / 2)
					
					# Paredes verticais
					create_wall(
						Vector3(pos_x, wall_height/2, pos_z),
						Vector3(0.2, wall_height, maze_cell_size)
					)

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
		
		# Defina tamanhos fixos para testar primeiro
		var floor_width = randf_range(3, 8)
		var floor_depth = randf_range(3, 8)
		var floor_thickness = 0.3  # Tamanho fixo para testar
		
		# MODIFICAÇÃO: Ajustar o mesh
		if mesh_instance:
			# Crie um novo BoxMesh se necessário
			var new_mesh = BoxMesh.new()
			new_mesh.size = Vector3(floor_width, floor_thickness, floor_depth)
			mesh_instance.mesh = new_mesh
		
		# MODIFICAÇÃO: Ajustar a colisão
		if collision_shape:
			# Crie um novo BoxShape3D se necessário
			var new_shape = BoxShape3D.new()
			new_shape.size = Vector3(floor_width, floor_thickness, floor_depth)
			collision_shape.shape = new_shape
		
		if randf() < fragile_floor_chance:
			floor_instance.Floor_type = 1
			# Adiciona um material vermelho para pisos frágeis
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.8, 0.3, 0.3)
			mesh_instance.material_override = material
		else:
			floor_instance.Floor_type = 0
			# Adiciona um material cinza para pisos sólidos
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.6, 0.6, 0.6)
			mesh_instance.material_override = material
		
		$FloatingFloors.add_child(floor_instance)
		
		# DEBUG: Verifique se a colisão está sendo aplicada
		print("Piso criado em: ", Vector3(pos_x, height, pos_z), 
			  " Tamanho: ", Vector3(floor_width, floor_thickness, floor_depth))