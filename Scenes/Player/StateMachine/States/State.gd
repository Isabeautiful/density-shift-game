class_name State
extends Node

# Sinal emitido quando queremos transicionar para outro estado
signal transitioned(state: State, new_state_name: String)

# Referência ao jogador e à máquina de estados (serão atribuídas pela StateMachine)
var player: CharacterBody3D
var state_machine: StateMachine

# Métodos que os estados concretos podem sobrescrever
func enter() -> void:
	pass

func exit() -> void:
	pass

func process_physics(_delta: float) -> void:
	pass

func process_input(_event: InputEvent, _player : CharacterBody3D) -> void:
	pass
