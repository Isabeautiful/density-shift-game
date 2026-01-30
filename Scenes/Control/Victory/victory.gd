extends Control

@onready var jogar: Button = $Panel/VBoxContainer/Jogar
@onready var tutorial: Button = $Panel/VBoxContainer/Voltar
@onready var sair: Button = $Panel/VBoxContainer/Sair

var intensidade = 1.25
var duracao = 0.5

@onready var hover_sound: AudioStreamPlayer = $hover
@onready var audio_stream_player: AudioStreamPlayer = $music
var num_Play = 0

func _process(_delta: float) -> void:
	btn_hover(jogar)
	btn_hover(tutorial)
	btn_hover(sair)
	
	if !audio_stream_player.playing:
		audio_stream_player.play(0.0)

func _on_jogar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Tutorial/TestLevel.tscn")
	
func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Tutorial/tutorial.tscn")
	
func _on_sair_pressed() -> void:
	get_tree().quit()
	
func hover(Obj:Object,property:String,value:Variant,duration:float):
	var tween = create_tween()
	tween.tween_property(Obj,property,value,duration)

func btn_hover(button:Button):
	button.pivot_offset = button.size/2
	
	if button.is_hovered():
		hover(button,"scale",Vector2.ONE*intensidade,duracao)
	else:
		hover(button,"scale",Vector2.ONE,duracao)

func _on_jogar_mouse_entered() -> void:
	hover_sound.play()

func _on_voltar_mouse_entered() -> void:
	hover_sound.play()

func _on_sair_mouse_entered() -> void:
	hover_sound.play()
