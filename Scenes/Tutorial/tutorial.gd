extends Node3D
@export var size_floor : int = 200
@export var size_wall : int = 300
@onready var player: CharacterBody3D = $Player
@onready var quebraveis: Node3D = $Quebraveis
@export var fragile_floor_scene : PackedScene

var player_start_pos : Vector3
var chao_position : Vector3
var conf_mesh_chao = Vector3(size_floor,0.1,size_floor)
var conf_parede = Vector3(size_wall,size_wall,0.1)
var floor_offset = 50
var player_offset = Vector3(0,5.8,0)
var color_fragile = Color(1.0, 0.404, 0.5, 1.0)
var color_rigid =   Color(0.665, 0.871, 1.0, 1.0)
var color_wall = Color("gray")

var platforms = []
var dialog = []
var platforms_dialog =[]
var already_shown_dialog_leve = false
var already_shown_break_tutorial = false

func _ready() -> void:
	player_start_pos = player.position - player_offset
	inicio()
	gerar_limites()
	init_dialogs()
	gerar_plataformas()
	
func gerar_limites():
	var chao = create_wall(Vector3(0,0,0),Vector3(size_floor,0.1,size_floor),Vector3(0,0,0))
	create_wall(Vector3(size_floor/2 - floor_offset,0,0),Vector3(size_wall,0.1,size_wall),Vector3(0,0,PI/2),false,false,color_wall)
	create_wall(Vector3(-size_floor/2 + floor_offset,0,0),Vector3(size_wall,0.1,size_wall),Vector3(0,0,PI/2),false,false,color_wall)
	create_wall(Vector3(0,0,size_floor/2 - floor_offset),Vector3(size_wall,0.1,size_wall),Vector3(PI/2,0,0),false,false,color_wall)
	create_wall(Vector3(0,0,-size_floor/2 + floor_offset),Vector3(size_wall,0.1,size_wall),Vector3(PI/2,0,0),false,false,color_wall)
	textura(chao["MeshInstance"])
	chao_position = chao["StaticBody"].position

func init_dialogs():
	dialog.push_back(null)
	dialog.push_back(dialog_p1)
	dialog.push_back(dialog_p2)
	dialog.push_back(break_tutorial_done)
	
func gerar_plataformas():
	platforms.push_back(create_wall(player_start_pos,Vector3(10,0.1,10),Vector3(0,0,0),true,false,color_rigid))
	platforms.push_back(create_wall(player_start_pos+Vector3(10,10,0),Vector3(10,0.1,10),Vector3(0,0,0),true,false,color_rigid))
	platforms.push_back(create_wall(player_start_pos+Vector3(30,5,0),Vector3(10,0.1,10),Vector3(0,0,0),true,true,color_fragile,2100))
	platforms.push_back(create_wall(player_start_pos+Vector3(30,20,20),Vector3(10,0.1,10),Vector3(0,0,0),true,false,color_fragile))
	
	for i in range(len(platforms)):
		if i<len(dialog) and dialog[i] != null:
			var group = ("Plat"+str(i))
			platforms[i]["StaticBody"].add_to_group(group)
			platforms_dialog.push_back({"already_shown":false,"dialog":dialog[i],"index":i,"group":group})
		
func textura(mesh_i):
	var material = StandardMaterial3D.new()
	var textura = load("res://assets/textures/CleanEdge_tileset.png")
	material.albedo_texture = textura
	mesh_i.material_override = material

func create_wall(pos:Vector3,mesh_size:Vector3= Vector3(10,0.1,25), 
	rotation: Vector3=Vector3(0,0,0),dupla_face:bool=false, is_fragile:int=0, 
	Cor:Color=Color(0.871, 0.562, 0.255, 1.0),break_strength:float=500.0):
		
	var floor_instance = fragile_floor_scene.instantiate()
	var mesh_i = floor_instance.get_node("MeshInstance3D")
	var collision_shape = floor_instance.get_node("CollisionShape3D")
	var mesh = BoxMesh.new()
	var shape = BoxShape3D.new()
	
	floor_instance.transform.origin = pos
	mesh_i.rotation_edit_mode = 0
	mesh_i.rotation = rotation
	collision_shape.rotation = rotation
	mesh.size = mesh_size
	shape.size = mesh_size
	mesh_i.position = pos
	collision_shape.position = pos
	
	mesh_i.mesh = mesh
	collision_shape.shape = shape
	
	floor_instance.Floor_type = is_fragile
	var material = StandardMaterial3D.new()
	if is_fragile == 1:
		floor_instance.fragile_floor_broke.connect(dialog_end)
		material.roughness = 0.7
		mesh_i.material_override = material
		floor_instance.set_break_force(break_strength)
	else:
		floor_instance.Floor_type = 0
		material.roughness = 0.8
		mesh_i.material_override = material
		
	material.albedo_color = Cor
	
	if dupla_face:
		desabilitar_culling_mesh(mesh_i)
		
	quebraveis.add_child(floor_instance)
	
	return {"StaticBody":floor_instance,"MeshInstance":mesh_i,"CollisionShape":collision_shape}
	
func desabilitar_culling_mesh(mesh_i):
	var material = mesh_i.get_surface_override_material(0)
	if material == null:
		material = StandardMaterial3D.new()
		mesh_i.set_surface_override_material(0, material)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

func show_dialog(texto:String,show_btn:bool,action:String="", funcao : Callable = Callable()):
	#player.set_dialog_text(texto)
	#player.show_btn(show_btn)
	#player.hide_dialog_by_input(action)
	player.show_message(texto,show_btn,action)
	if funcao != Callable():
		player.button_pressed.connect(funcao)
	
func inicio():
	show_dialog("Bem vindo a density shift!\n nesse jogo a principal mecânica é sobre o controle do peso
	do seu corpo, aperte a tecla 1 para entrar no modo leve e seguir em frente",false,"toggle_light")
func dialog_leve():
	show_dialog("Agora você está no estado leve, nesse estado você consegue dar longos pulos duplos e alcançar grandes alturas, experimente subir nas plataformas
	a sua frente para continuar",true,"")
func dialog_p1():
	show_dialog("Há dois tipos de piso, o azul que é o piso resistente, e o rosa que é o piso frágil, é possível quebrar
	o piso frágil ao cair de bem alto enquanto está no modo pesado segurando a tecla shift, experimente tentar quebrar o piso 
	frágil a frente",true,"")

func dialog_p2():
	show_dialog("Hmm, parece que você não obteve energia o suficiente para quebrar esse piso caindo dessa altura,
	tente subir em uma plataforma mais alta",true,"")

func break_tutorial_done():
	already_shown_break_tutorial = true

func dialog_end():
	show_dialog("Tutorial Concluído!",true,"",toMainMenu)
func toMainMenu():
	get_tree().change_scene_to_file("res://Scenes/Control/MainMenu/MainMenu.tscn")
	
func wrong_mode_dialog():
	show_dialog("lembre-se, para quebrar chãos frágeis você deve cair no modo pesado, segurando shift",true,"")
	already_shown_break_tutorial = false
	await get_tree().create_timer(30).timeout
	already_shown_break_tutorial = true
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_light") and not already_shown_dialog_leve:
		dialog_leve()
		already_shown_dialog_leve = true
	
	trigger_dialog()
	touch_grass()
	
func trigger_dialog():
	for i in platforms_dialog:
		#print(player.position,i["group"])
		if verify_collision(i["index"],i["dialog"],i["already_shown"]):
			i["already_shown"] = true
			

func touch_grass():
	print(player.global_position, chao_position)
	if player.global_position.y - chao_position.y < 0.2 :#se tocou o chao
		player.global_position = platforms[0]["StaticBody"].position + Vector3(0,0.2,0)

func verify_collision(index:int,dialog:Callable,already_shown:bool):
	var space_state = player.get_world_3d().direct_space_state
	var from = player.global_position
	var to = from - Vector3(0, 1.5, 0)
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	var result = space_state.intersect_ray(query)
	var is_breaking = Input.is_action_pressed("break_floor")
	
	if result:
		var collider = result.collider
		print(already_shown_break_tutorial,collider.get_groups(), is_breaking)
		if already_shown_break_tutorial and collider.is_in_group("fragile_floor") and not is_breaking:
			wrong_mode_dialog()
			
		if not already_shown:
			if collider.is_in_group("Plat"+str(index)):
				dialog.call()
				return true
			
	return false
