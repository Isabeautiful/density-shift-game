extends Node3D

@export var floor_grid_size: float = 180
@export var floor_spacing: float = 8.0
@export var floor_thickness: float = 0.3
@export var fragile_chance: float = 0.3
@export var spawn_margin: float = 3.0
@export var generate_maze: bool = true
@export var wall_height: float = 10.0
@export var wall_density: float = 0.4
@export var wall_thickness: float = 0.5
@export var num_floors: int = 3
@export var floor_spacing_vertical: float = 10.0
@export var first_floor_height: float = 5.0
@export var portal_scene: PackedScene
@export var spawn_portal_on_top_floor: bool = true
@export var portal_height_offset: float = 1.5

@onready var floor_scene = preload("res://Scenes/Floor/floor.tscn")
@onready var wall_scene = preload("res://Scenes/TowerFloor/Wall.tscn")

var victory_portal: Area3D = null
var external_walls = []
var wall_collision_shapes = []
var spawned_floors_by_level = []

func _ready():
	spawned_floors_by_level = []
	for i in range(num_floors):
		spawned_floors_by_level.append([])
	
	find_external_walls()
	
	for floor_level in range(num_floors):
		generate_floor_level(floor_level)
	
	if portal_scene:
		call_deferred("spawn_victory_portal")

func find_external_walls():
	for child in get_children():
		if child is StaticBody3D and child != $chao:
			external_walls.append(child)

func cache_wall_collisions():
	wall_collision_shapes.clear()
	
	for wall in external_walls:
		if wall != null:
			var collision = wall.get_node_or_null("CollisionShape3D")
			if collision != null and collision.shape != null:
				var global_transform = wall.global_transform
				var shape = collision.shape
				
				if shape is BoxShape3D:
					var shape_size = shape.size
					var aabb_position = global_transform.origin - shape_size/2
					var aabb_size = shape_size
					var wall_aabb = AABB(aabb_position, aabb_size)
					wall_aabb = wall_aabb.grow(spawn_margin)
					wall_collision_shapes.append(wall_aabb)

func is_position_valid(position: Vector3, size: Vector3, ignore_y: bool = false) -> bool:
	var obj_aabb = AABB(position - size/2, size)
	
	if ignore_y:
		obj_aabb.position.y = -1000
		obj_aabb.size.y = 2000
	
	for wall_aabb in wall_collision_shapes:
		if obj_aabb.intersects(wall_aabb):
			return false
	
	var half_grid = floor_grid_size / 2.0
	if (abs(position.x) > half_grid - spawn_margin or 
		abs(position.z) > half_grid - spawn_margin):
		return false
	
	return true

func generate_floor_level(floor_level: int):
	var floor_y = first_floor_height + (floor_level * floor_spacing_vertical)
	
	cache_wall_collisions()
	
	generate_floors_grid_for_level(floor_y, floor_level)
	
	if generate_maze:
		generate_maze_walls_for_level(floor_y, floor_level)

func generate_floors_grid_for_level(floor_y: float, floor_level: int):
	var floors_per_side = int(floor_grid_size / floor_spacing)
	var start_offset = -(floors_per_side - 1) * floor_spacing / 2.0
	
	var total_floors = 0
	var spawned_floors = 0
	
	for i in range(floors_per_side):
		for j in range(floors_per_side):
			var pos_x = start_offset + i * floor_spacing
			var pos_z = start_offset + j * floor_spacing
			var position = Vector3(pos_x, floor_y, pos_z)
			var size = Vector3(floor_spacing, floor_thickness, floor_spacing)
			
			if is_position_valid(position, size, true):
				var current_fragile_chance = fragile_chance + (floor_level * 0.15)
				var is_fragile = randf() < current_fragile_chance
				var floor_instance = spawn_floor(position, size, is_fragile, floor_level)
				spawned_floors_by_level[floor_level].append(floor_instance)
				spawned_floors += 1
			
			total_floors += 1

func spawn_floor(position: Vector3, size: Vector3, is_fragile: bool, floor_level: int) -> StaticBody3D:
	var floor_instance = floor_scene.instantiate()
	floor_instance.transform.origin = position
	
	if is_fragile:
		floor_instance.Floor_type = 1
	else:
		floor_instance.Floor_type = 0
	
	var mesh_instance = floor_instance.get_node("MeshInstance3D")
	var collision_shape = floor_instance.get_node("CollisionShape3D")
	
	if mesh_instance:
		var new_mesh = BoxMesh.new()
		new_mesh.size = size
		mesh_instance.mesh = new_mesh
		
		var material = StandardMaterial3D.new()
		if is_fragile:
			var red_shade = 0.8 - (floor_level * 0.1)
			material.albedo_color = Color(red_shade, 0.2, 0.2, 0.9)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.roughness = 0.7
		else:
			var gray_shade = 0.7 - (floor_level * 0.1)
			material.albedo_color = Color(gray_shade, gray_shade, gray_shade)
			material.roughness = 0.8
		mesh_instance.material_override = material
	
	if collision_shape:
		var new_shape = BoxShape3D.new()
		new_shape.size = size
		collision_shape.shape = new_shape
	
	add_child(floor_instance)
	return floor_instance

func generate_maze_walls_for_level(floor_y: float, floor_level: int):
	var cells_per_side = int(floor_grid_size / floor_spacing)
	var start_offset = -(cells_per_side - 1) * floor_spacing / 2.0
	
	var total_walls = 0
	var spawned_walls = 0
	
	var wall_y = floor_y + (wall_height / 2)
	
	for i in range(cells_per_side + 1):
		for j in range(cells_per_side):
			var current_wall_density = wall_density * (1.0 - (floor_level * 0.1))
			current_wall_density = max(0.1, current_wall_density)
			
			var should_place_wall = randf() < current_wall_density
			
			if (i == 0 or i == cells_per_side) and (j == 0 or j == cells_per_side - 1):
				should_place_wall = false
			
			if should_place_wall:
				var pos_x = start_offset + i * floor_spacing - floor_spacing/2
				var pos_z = start_offset + j * floor_spacing
				var position = Vector3(pos_x, wall_y, pos_z)
				var size = Vector3(wall_thickness, wall_height, floor_spacing)
				
				if is_position_valid(position, size, true):
					spawn_wall(position, size, false, floor_level, floor_y)
					spawned_walls += 1
				
				total_walls += 1
	
	for i in range(cells_per_side):
		for j in range(cells_per_side + 1):
			var current_wall_density = wall_density * (1.0 - (floor_level * 0.1))
			current_wall_density = max(0.1, current_wall_density)
			
			var should_place_wall = randf() < current_wall_density
			
			if (j == 0 or j == cells_per_side) and (i == 0 or i == cells_per_side - 1):
				should_place_wall = false
			
			if should_place_wall:
				var pos_x = start_offset + i * floor_spacing
				var pos_z = start_offset + j * floor_spacing - floor_spacing/2
				var position = Vector3(pos_x, wall_y, pos_z)
				var size = Vector3(floor_spacing, wall_height, wall_thickness)
				
				if is_position_valid(position, size, true):
					spawn_wall(position, size, true, floor_level, floor_y)
					spawned_walls += 1
				
				total_walls += 1

func spawn_wall(position: Vector3, size: Vector3, is_vertical: bool, floor_level: int, floor_y: float):
	var wall_instance = wall_scene.instantiate()
	wall_instance.transform.origin = position
	
	var mesh_instance = wall_instance.get_node("MeshInstance3D")
	var collision_shape = wall_instance.get_node("CollisionShape3D")
	
	if mesh_instance:
		var new_mesh = BoxMesh.new()
		new_mesh.size = size
		mesh_instance.mesh = new_mesh
		
		var material = StandardMaterial3D.new()
		var color_value = 0.6 - (floor_level * 0.1)
		color_value = max(0.3, color_value)
		material.albedo_color = Color(color_value, color_value, color_value)
		material.roughness = 0.9
		
		if wall_height > 5.0:
			var shader_material = ShaderMaterial.new()
			var shader_code = """
			shader_type spatial;
			
			uniform vec3 top_color = vec3(0.3, 0.3, 0.3);
			uniform vec3 bottom_color = vec3(0.6, 0.6, 0.6);
			
			void fragment() {
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
	
	if is_vertical:
		wall_instance.rotate_y(PI / 2)
	
	add_child(wall_instance)

func spawn_victory_portal():
	var target_floor_level: int
	if spawn_portal_on_top_floor:
		target_floor_level = num_floors - 1
	else:
		target_floor_level = randi() % num_floors
	
	if target_floor_level >= spawned_floors_by_level.size():
		return
	
	var valid_floors = []
	for floor_instance in spawned_floors_by_level[target_floor_level]:
		if is_instance_valid(floor_instance) and floor_instance.is_inside_tree():
			if floor_instance.Floor_type == 0:
				valid_floors.append(floor_instance)
	
	if valid_floors.size() == 0:
		return
	
	var random_floor = valid_floors[randi() % valid_floors.size()]
	var floor_position: Vector3
	
	if random_floor.is_inside_tree():
		floor_position = random_floor.global_transform.origin
	else:
		floor_position = random_floor.transform.origin
	
	var portal_position = Vector3(
		floor_position.x,
		floor_position.y + portal_height_offset,
		floor_position.z
	)
	
	victory_portal = portal_scene.instantiate()
	add_child(victory_portal)
	victory_portal.global_transform.origin = portal_position
	
	if victory_portal.has_signal("player_entered_portal"):
		victory_portal.player_entered_portal.connect(_on_player_reached_portal)
	else:
		victory_portal.body_entered.connect(_on_portal_body_entered)

func _on_portal_body_entered(body):
	if body.is_in_group("player"):
		_on_player_reached_portal()

func _on_player_reached_portal():
	show_victory_screen()

func show_victory_screen():
	get_tree().paused = true
	
	var victory_label = Label.new()
	victory_label.text = "VITÓRIA!\nFase Concluída!\n\nPressione R para reiniciar"
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	victory_label.add_theme_font_size_override("font_size", 48)
	victory_label.add_theme_color_override("font_color", Color(0, 1, 1))
	victory_label.size = Vector2(800, 600)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(victory_label)
	add_child(canvas)
	
	victory_label.position = Vector2(
		get_viewport().size.x / 2 - victory_label.size.x / 2,
		get_viewport().size.y / 2 - victory_label.size.y / 2
	)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
