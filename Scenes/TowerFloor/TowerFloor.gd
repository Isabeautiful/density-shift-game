extends Node3D

# Configurações da grade de pisos
@export var floor_grid_size: float = 180  # Tamanho da área onde os pisos serão spawnados
@export var floor_spacing: float = 8.0   # Espaçamento entre pisos (horizontal) - AGORA É O TAMANHO DO PISO
@export var floor_thickness: float = 0.3 # Espessura dos pisos
@export var fragile_chance: float = 0.3  # Chance de ser piso frágil (0.0 a 1.0)
@export var spawn_margin: float = 3.0    # Margem para não spawnar perto das paredes

# Configurações do labirinto
@export var generate_maze: bool = true   # Se deve gerar paredes do labirinto
@export var wall_height: float = 10.0    # Altura das paredes internas (AUMENTADA para tocar o chão do próximo andar)
@export var wall_density: float = 0.4    # Densidade das paredes (0.0 a 1.0)
@export var wall_thickness: float = 0.5  # Espessura das paredes (aumentada para ficar mais visível)

# Configurações dos andares múltiplos
@export var num_floors: int = 3          # Número de andares
@export var floor_spacing_vertical: float = 10.0  # Espaçamento vertical entre andares
@export var first_floor_height: float = 5.0  # Altura do primeiro andar

# Cenas dos pisos e paredes
@onready var floor_scene = preload("res://Scenes/Floor/floor.tscn")
@onready var wall_scene = preload("res://Scenes/TowerFloor/Wall.tscn")

# Configurações do portal
@export var portal_scene: PackedScene
@export var spawn_portal_on_top_floor: bool = true
@export var portal_height_offset: float = 1.5  # Altura acima do piso

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

# Referência ao portal instanciado
var victory_portal: Area3D = null

# Referências às paredes externas (serão preenchidas automaticamente)
var external_walls = []

# Cache para colisões das paredes externas
var wall_collision_shapes = []

# Variável para rastrear pisos spawnados por andar
var spawned_floors_by_level = []

func _ready():
	audio_stream_player.play()
	# Inicializar array para rastrear pisos
	spawned_floors_by_level = []
	for i in range(num_floors):
		spawned_floors_by_level.append([])
	
	# Encontrar todas as paredes externas automaticamente
	find_external_walls()
	
	# Gerar múltiplos andares
	for floor_level in range(num_floors):
		generate_floor_level(floor_level)
	
	# Spawnar portal de vitória (se houver cena configurada)
	# Usar call_deferred para garantir que tudo esteja na árvore
	if portal_scene:
		call_deferred("spawn_victory_portal")

func find_external_walls():
	# Encontrar todas as paredes externas (StaticBody3D que não são o chão)
	for child in get_children():
		if child is StaticBody3D and child != $chao:
			external_walls.append(child)
	
	print("Encontradas ", external_walls.size(), " paredes externas")

func cache_wall_collisions():
	wall_collision_shapes.clear()
	
	# Coletar todas as formas de colisão das paredes externas
	for wall in external_walls:
		if wall != null:
			var collision = wall.get_node_or_null("CollisionShape3D")
			if collision != null and collision.shape != null:
				# Obter transform global
				var global_transform = wall.global_transform
				var shape = collision.shape
				
				if shape is BoxShape3D:
					# Calcular AABB aproximado
					var shape_size = shape.size
					var wall_transform = wall.transform
					
					# Calcular AABB
					var aabb_position = global_transform.origin - shape_size/2
					var aabb_size = shape_size
					
					# Criar AABB
					var wall_aabb = AABB(aabb_position, aabb_size)
					wall_aabb = wall_aabb.grow(spawn_margin)
					
					wall_collision_shapes.append(wall_aabb)

func is_position_valid(position: Vector3, size: Vector3, ignore_y: bool = false) -> bool:
	# Criar AABB do objeto
	var obj_aabb = AABB(position - size/2, size)
	
	# Se ignore_y for true, expandir o AABB no eixo Y para ignorar verificação vertical
	if ignore_y:
		obj_aabb.position.y = -1000  # Valor muito baixo
		obj_aabb.size.y = 2000       # Valor muito alto
	
	# Verificar colisão com paredes externas
	for wall_aabb in wall_collision_shapes:
		if obj_aabb.intersects(wall_aabb):
			return false
	
	# Verificar se está muito perto das bordas
	var half_grid = floor_grid_size / 2.0
	if (abs(position.x) > half_grid - spawn_margin or 
		abs(position.z) > half_grid - spawn_margin):
		return false
	
	return true

func generate_floor_level(floor_level: int):
	print("Gerando andar ", floor_level + 1, " de ", num_floors)
	
	# Calcular altura deste andar
	var floor_y = first_floor_height + (floor_level * floor_spacing_vertical)
	
	# Primeiro cache das colisões das paredes externas
	cache_wall_collisions()
	
	# Gerar pisos para este andar
	generate_floors_grid_for_level(floor_y, floor_level)
	
	# Gerar paredes do labirinto para este andar (se habilitado)
	if generate_maze:
		generate_maze_walls_for_level(floor_y, floor_level)

func generate_floors_grid_for_level(floor_y: float, floor_level: int):
	# Calcular número de pisos em cada direção
	var floors_per_side = int(floor_grid_size / floor_spacing)
	
	# Começar a partir do centro
	var start_offset = -(floors_per_side - 1) * floor_spacing / 2.0
	
	# Contadores para debug
	var total_floors = 0
	var spawned_floors = 0
	
	# Percorrer grade
	for i in range(floors_per_side):
		for j in range(floors_per_side):
			# Calcular posição - AGORA OS PISOS SE TOCAM PERFEITAMENTE
			var pos_x = start_offset + i * floor_spacing
			var pos_z = start_offset + j * floor_spacing
			var position = Vector3(pos_x, floor_y, pos_z)
			
			# Tamanho do piso - AGORA É EXATAMENTE O FLOOR_SPACING (sem gaps)
			var size = Vector3(floor_spacing, floor_thickness, floor_spacing)
			
			# Verificar se a posição é válida (ignorando verificação Y para evitar problemas com pisos acima/abaixo)
			if is_position_valid(position, size, true):
				# Decidir tipo de piso - andares mais altos têm maior chance de serem frágeis
				var current_fragile_chance = fragile_chance + (floor_level * 0.15)
				var is_fragile = randf() < current_fragile_chance
				var floor_instance = spawn_floor(position, size, is_fragile, floor_level)
				spawned_floors_by_level[floor_level].append(floor_instance)
				spawned_floors += 1
			
			total_floors += 1
	
	print("Andar %d: Gerados %d de %d pisos" % [floor_level + 1, spawned_floors, total_floors])

func spawn_floor(position: Vector3, size: Vector3, is_fragile: bool, floor_level: int) -> StaticBody3D:
	# Instanciar piso
	var floor_instance = floor_scene.instantiate()
	floor_instance.transform.origin = position
	
	# Configurar tipo de piso
	if is_fragile:
		floor_instance.Floor_type = 1  # Frágil
	else:
		floor_instance.Floor_type = 0  # Rígido
	
	# Configurar mesh e colisão
	var mesh_instance = floor_instance.get_node("MeshInstance3D")
	var collision_shape = floor_instance.get_node("CollisionShape3D")
	
	if mesh_instance:
		var new_mesh = BoxMesh.new()
		new_mesh.size = size
		mesh_instance.mesh = new_mesh
		
		# Aplicar material baseado no tipo e andar
		var material = StandardMaterial3D.new()
		if is_fragile:
			# Tons de vermelho diferentes por andar
			var red_shade = 0.8 - (floor_level * 0.1)
			material.albedo_color = Color(red_shade, 0.2, 0.2, 0.9)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.roughness = 0.7
		else:
			# Tons de cinza diferentes por andar
			var gray_shade = 0.7 - (floor_level * 0.1)
			material.albedo_color = Color(gray_shade, gray_shade, gray_shade)
			material.roughness = 0.8
		mesh_instance.material_override = material
	
	if collision_shape:
		var new_shape = BoxShape3D.new()
		new_shape.size = size
		collision_shape.shape = new_shape
	
	# Adicionar à cena
	add_child(floor_instance)
	return floor_instance

func generate_maze_walls_for_level(floor_y: float, floor_level: int):
	# Calcular número de células do labirinto
	var cells_per_side = int(floor_grid_size / floor_spacing)
	
	# Começar a partir do centro
	var start_offset = -(cells_per_side - 1) * floor_spacing / 2.0
	
	# Contadores para debug
	var total_walls = 0
	var spawned_walls = 0
	
	# Ajustar altura da parede para este andar
	# AGORA: A parede começa no nível do chão (floor_y) e vai para cima
	var wall_y = floor_y + (wall_height / 2)  # Centro da parede (altura/2 acima do chão)
	
	# Percorrer todas as linhas e colunas para criar paredes
	for i in range(cells_per_side + 1):  # +1 para paredes nas bordas
		for j in range(cells_per_side):
			# Decidir se coloca parede horizontal entre as células
			# Andares mais altos têm paredes menos densas para mais desafio
			var current_wall_density = wall_density * (1.0 - (floor_level * 0.1))
			current_wall_density = max(0.1, current_wall_density)  # Mínimo de 10%
			
			# Verificar se esta parede bloquearia o único caminho
			var should_place_wall = randf() < current_wall_density
			
			# Se for a primeira ou última linha, não colocar paredes para garantir entrada/saída
			if (i == 0 or i == cells_per_side) and (j == 0 or j == cells_per_side - 1):
				should_place_wall = false
			
			if should_place_wall:
				var pos_x = start_offset + i * floor_spacing - floor_spacing/2
				var pos_z = start_offset + j * floor_spacing
				var position = Vector3(pos_x, wall_y, pos_z)
				
				# Tamanho da parede horizontal - ajustado para ficar entre os pisos
				var size = Vector3(wall_thickness, wall_height, floor_spacing)
				
				# Verificar se a posição é válida (ignorando Y para paredes)
				if is_position_valid(position, size, true):
					spawn_wall(position, size, false, floor_level, floor_y)  # false = horizontal
					spawned_walls += 1
				
				total_walls += 1
	
	for i in range(cells_per_side):
		for j in range(cells_per_side + 1):  # +1 para paredes nas bordas
			# Decidir se coloca parede vertical entre as células
			var current_wall_density = wall_density * (1.0 - (floor_level * 0.1))
			current_wall_density = max(0.1, current_wall_density)  # Mínimo de 10%
			
			# Verificar se esta parede bloquearia o único caminho
			var should_place_wall = randf() < current_wall_density
			
			# Se for a primeira ou última coluna, não colocar paredes para garantir entrada/saída
			if (j == 0 or j == cells_per_side) and (i == 0 or i == cells_per_side - 1):
				should_place_wall = false
			
			if should_place_wall:
				var pos_x = start_offset + i * floor_spacing
				var pos_z = start_offset + j * floor_spacing - floor_spacing/2
				var position = Vector3(pos_x, wall_y, pos_z)
				
				# Tamanho da parede vertical - ajustado para ficar entre os pisos
				var size = Vector3(floor_spacing, wall_height, wall_thickness)
				
				# Verificar se a posição é válida (ignorando Y para paredes)
				if is_position_valid(position, size, true):
					spawn_wall(position, size, true, floor_level, floor_y)  # true = vertical
					spawned_walls += 1
				
				total_walls += 1
	
	print("Andar %d: Geradas %d de %d paredes" % [floor_level + 1, spawned_walls, total_walls])

func spawn_wall(position: Vector3, size: Vector3, is_vertical: bool, floor_level: int, floor_y: float):
	# Instanciar parede
	var wall_instance = wall_scene.instantiate()
	wall_instance.transform.origin = position
	
	# Configurar mesh e colisão
	var mesh_instance = wall_instance.get_node("MeshInstance3D")
	var collision_shape = wall_instance.get_node("CollisionShape3D")
	
	if mesh_instance:
		var new_mesh = BoxMesh.new()
		new_mesh.size = size
		mesh_instance.mesh = new_mesh
		
		# Aplicar material às paredes - tons diferentes por andar
		var material = StandardMaterial3D.new()
		# Andares mais altos têm paredes mais escuras
		var color_value = 0.6 - (floor_level * 0.1)
		color_value = max(0.3, color_value)  # Mínimo de 0.3
		material.albedo_color = Color(color_value, color_value, color_value)
		material.roughness = 0.9
		
		# Se a parede for muito alta, adicionar um gradiente visual
		if wall_height > 5.0:
			# Criar um ShaderMaterial com gradiente
			var shader_material = ShaderMaterial.new()
			var shader_code = """
			shader_type spatial;
			
			uniform vec3 top_color = vec3(0.3, 0.3, 0.3);
			uniform vec3 bottom_color = vec3(0.6, 0.6, 0.6);
			
			void fragment() {
				// Gradiente baseado na coordenada Y local (0 a 1)
				float mix_value = VERTEX.y / %f;
				ALBEDO = mix(bottom_color, top_color, mix_value);
				ROUGHNESS = 0.9;
			}
			""" % wall_height
			
			var shader = Shader.new()
			shader.code = shader_code
			shader_material.shader = shader
			mesh_instance.material_override = shader_material
		else:
			mesh_instance.material_override = material
	
	if collision_shape:
		var new_shape = BoxShape3D.new()
		new_shape.size = size
		collision_shape.shape = new_shape
	
	# Rotacionar se for vertical (90 graus em Y)
	if is_vertical:
		wall_instance.rotate_y(PI / 2)
	
	# Adicionar à cena
	add_child(wall_instance)

# Função para adicionar conexões verticais entre andares (escadas/buracos)
func add_vertical_connections():
	for floor_level in range(num_floors - 1):
		# Encontrar alguns pisos para remover, criando buracos para subir/descer
		var floors_in_level = spawned_floors_by_level[floor_level]
		if floors_in_level.size() > 4:  # Pelo menos 4 pisos no andar
			# Escolher 2-3 pisos aleatórios para remover
			var holes_to_create = min(3, floors_in_level.size() / 4)
			for h in range(holes_to_create):
				var random_index = randi() % floors_in_level.size()
				var floor_to_remove = floors_in_level[random_index]
				# Marcar o piso como frágil que desaparece após uso
				floor_to_remove.Floor_type = 1
				# Aplicar material especial para buraco
				var mesh_instance = floor_to_remove.get_node("MeshInstance3D")
				if mesh_instance:
					var material = StandardMaterial3D.new()
					material.albedo_color = Color(0.2, 0.7, 0.2, 0.5)  # Verde semi-transparente
					material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
					mesh_instance.material_override = material
				
				print("Criado buraco no andar ", floor_level + 1, " na posição ", floor_to_remove.transform.origin)
	if Input.is_action_just_pressed("ui_accept"):
		print("--- Regenerando todos os andares ---")
		
		# Limpar arrays de rastreamento
		for i in range(spawned_floors_by_level.size()):
			spawned_floors_by_level[i].clear()
		
		# Remover todos os pisos e paredes internas existentes
		for child in get_children():
			# Verifica se é uma instância de floor ou wall (não as paredes externas)
			if child != $chao and child not in external_walls and child != $Player and child != $DirectionalLight3D and child != $OmniLight3D:
				if child.get_script() != null:
					# É um piso (tem script floor.gd)
					if child.get_script().resource_path.contains("floor.gd"):
						child.queue_free()
				else:
					# É uma parede interna (não tem script e não está na lista de paredes externas)
					# Verificar se tem MeshInstance3D (é uma parede gerada)
					if child.get_node_or_null("MeshInstance3D") != null:
						child.queue_free()
		
		# Gerar novos andares
		for floor_level in range(num_floors):
			generate_floor_level(floor_level)
		
		# Adicionar conexões verticais
		add_vertical_connections()
	
	# Tecla V para adicionar conexões verticais
	if Input.is_action_just_pressed("ui_home"):
		add_vertical_connections()
		print("Conexões verticais adicionadas/atualizadas")

func spawn_victory_portal():
	# Determinar em qual andar spawnar o portal
	var target_floor_level: int
	if spawn_portal_on_top_floor:
		target_floor_level = num_floors - 1  # Último andar
	else:
		target_floor_level = randi() % num_floors  # Andar aleatório
	
	# Verificar se temos andares gerados
	if target_floor_level >= spawned_floors_by_level.size():
		print("⚠️ Andar alvo para portal inválido")
		return
	
	# Encontrar pisos válidos nesse andar
	var valid_floors = []
	for floor_instance in spawned_floors_by_level[target_floor_level]:
		# Verificar se o piso ainda existe na árvore
		if is_instance_valid(floor_instance) and floor_instance.is_inside_tree():
			# Verificar se o piso é sólido (não frágil) para o portal
			if floor_instance.Floor_type == 0:  # 0 = sólido
				valid_floors.append(floor_instance)
	
	if valid_floors.size() == 0:
		print("⚠️ Não há pisos sólidos no andar ", target_floor_level + 1, " para spawnar o portal")
		return
	
	# Escolher um piso aleatório
	var random_floor = valid_floors[randi() % valid_floors.size()]
	
	# Usar transform local se o nó estiver na árvore
	var floor_position: Vector3
	if random_floor.is_inside_tree():
		floor_position = random_floor.global_transform.origin
	else:
		# Se não estiver na árvore, usar a posição local
		floor_position = random_floor.transform.origin
	
	# Calcular posição do portal (centro do piso, com offset de altura)
	var portal_position = Vector3(
		floor_position.x,
		floor_position.y + portal_height_offset,
		floor_position.z
	)
	
	# Instanciar portal
	victory_portal = portal_scene.instantiate()
	
	# Adicionar à cena PRIMEIRO para depois definir a posição
	add_child(victory_portal)
	victory_portal.global_transform.origin = portal_position
	
	# Verificar se o portal tem o sinal antes de conectar
	if victory_portal.has_signal("player_entered_portal"):
		victory_portal.player_entered_portal.connect(_on_player_reached_portal)
	else:
		# Se não tiver o sinal, conectar ao sinal body_entered diretamente
		print("⚠️ Portal não tem sinal 'player_entered_portal', usando body_entered")
		victory_portal.body_entered.connect(_on_portal_body_entered)
	
	print("✅ Portal spawnado no andar ", target_floor_level + 1)
	print("   Posição: ", portal_position)

# Função alternativa se o portal não tiver sinal
func _on_portal_body_entered(body):
	if body.is_in_group("player"):
		print("🎉 Jogador entrou no portal (via body_entered)!")
		_on_player_reached_portal()

func _on_player_reached_portal():
	print("🎊 VITÓRIA! Fase concluída com sucesso!")
	
	# Aqui você pode adicionar lógica de vitória:
	# 1. Mostrar tela de vitória
	# 2. Salvar progresso
	# 3. Carregar próxima fase
	
	show_victory_screen()

func show_victory_screen():
	# Método simples: mostrar mensagem no console e recarregar cena após delay
	print("=====================================")
	print("         PARABÉNS! VENCEU!")
	print("=====================================")
	
	# Pausar o jogo
	get_tree().paused = true
	
	# Aqui você pode criar uma UI de vitória
	# Por enquanto, vamos apenas criar um label simples
	
	var victory_label = Label.new()
	victory_label.text = "VITÓRIA!\nFase Concluída!\n\nPressione R para reiniciar"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.add_theme_font_size_override("font_size", 48)
	victory_label.add_theme_color_override("font_color", Color(0, 1, 1))
	victory_label.size = Vector2(800, 600)
	
	# Criar um CanvasLayer para a UI
	var canvas = CanvasLayer.new()
	canvas.layer = 100  # Camada alta para ficar na frente
	canvas.add_child(victory_label)
	add_child(canvas)
	
	# Centralizar o label
	victory_label.position = Vector2(
		get_viewport().size.x / 2 - victory_label.size.x / 2,
		get_viewport().size.y / 2 - victory_label.size.y / 2
	)
	
	# Conectar input para reiniciar
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
