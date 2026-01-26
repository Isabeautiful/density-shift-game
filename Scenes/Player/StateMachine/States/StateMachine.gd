class_name StateMachine
extends Node

@export var initial_state_path: NodePath  # Use NodePath

var current_state: State
var states: Dictionary = {}

func init(player: CharacterBody3D) -> void:
	print("StateMachine: Inicializando...")
	
	# Inicializa todos os estados filhos
	for child in get_children():
		if child is State:
			print("StateMachine: Adicionando estado ", child.name)
			child.player = player
			child.state_machine = self
			states[child.name] = child
			child.transitioned.connect(_on_state_transitioned)
	
	# Define o estado inicial usando o NodePath
	if initial_state_path:
		var initial_state_node = get_node_or_null(initial_state_path)
		if initial_state_node and initial_state_node is State:
			print("StateMachine: Estado inicial definido como: ", initial_state_node.name)
			current_state = initial_state_node
			current_state.enter()
		else:
			push_error("O nó inicial não é um State válido ou não foi encontrado!")
			# Se não encontrar pelo NodePath, tenta usar o primeiro estado
			if states.size() > 0:
				current_state = states.values()[0]
				current_state.enter()
				print("StateMachine: Usando primeiro estado disponível: ", current_state.name)
	else:
		push_error("Nenhum estado inicial definido!")
		# Se não houver NodePath, tenta usar o primeiro estado
		if states.size() > 0:
			current_state = states.values()[0]
			current_state.enter()
			print("StateMachine: Usando primeiro estado disponível: ", current_state.name)

func process_physics(delta: float) -> void:
	if current_state:
		current_state.process_physics(delta)
	else:
		print("StateMachine: Nenhum estado atual!")

func process_input(event: InputEvent) -> void:
	if current_state:
		current_state.process_input(event)

func change_state(new_state_name: String) -> void:
	if not new_state_name in states:
		push_error("Estado não encontrado: " + new_state_name)
		return
	
	var new_state = states[new_state_name]
	
	if current_state:
		current_state.exit()
	
	current_state = new_state
	current_state.enter()
	print("StateMachine: Mudou para estado ", new_state_name)

func _on_state_transitioned(state: State, new_state_name: String) -> void:
	if state != current_state:
		return
	
	change_state(new_state_name)
