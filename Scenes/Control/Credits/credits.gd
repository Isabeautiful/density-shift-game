extends Control
@onready var label: RichTextLabel = $Panel3/Label
@onready var voltar: Button = $Panel/VBoxContainer/Voltar
@onready var hover_sound: AudioStreamPlayer = $hover
@onready var music: AudioStreamPlayer = $music

var typing_speed = 0.01
var is_typing = true
var intensidade = 1.25
var duracao = 0.5

func _ready() -> void:
	music.stream.loop = true
	type_text("""
	Alunos:
	Isabela Coelho
	Igor Correa Trifilio Campos
	
	textura:
	[url]https://jarzarr.itch.io/grass-dirt-tileset[/url]
	mão:
	[url]https://teamfuze.itch.io/hands-3d-pack[/url]
	fonte:
	[url]https://ggbot.itch.io/alpha-prota-font[/url]
	[url]https://ggbot.itch.io/linerama-font[/url]

	musica:
	[url]https://comigo.itch.io/music-loops[/url]
	""")
	
func type_text(text:String):
	for i in range(text.length()):
			label.text += text[i]
			await get_tree().create_timer(typing_speed).timeout
	
	is_typing = false
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	btn_hover(voltar)
	
func hover(Obj,property:String,value:Variant,duration:float):
	var tween = create_tween()
	tween.tween_property(Obj,property,value,duration)

func btn_hover(button:Button):
	button.pivot_offset = button.size/2
	
	if button.is_hovered():
		hover(button,"scale",Vector2.ONE*intensidade,duracao)
	else:
		hover(button,"scale",Vector2.ONE,duracao)

func _on_label_meta_clicked(meta: Variant) -> void:
	print("Link clicado: ", meta)
	
	# Se for URL externa
	if meta.begins_with("http") or meta.begins_with("https"):
		OS.shell_open(meta)

func _on_voltar_mouse_entered() -> void:
	hover_sound.play()

func _on_label_meta_hover_started(meta: Variant) -> void:
	if not is_typing:
		hover_sound.play()

func _on_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Control/MainMenu/MainMenu.tscn")
