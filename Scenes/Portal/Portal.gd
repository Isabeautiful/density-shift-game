extends Area3D

# Sinal emitido quando o jogador entra no portal
signal player_entered_portal

@export var rotation_speed: float = 45.0  # Graus por segundo
@export var bob_speed: float = 1.5        # Velocidade do movimento vertical
@export var bob_height: float = 0.3       # Altura do movimento vertical

var original_y: float
var time: float = 0.0

func _ready():
	print("Portal: Inicializando...")
	original_y = position.y
	
	# DEBUG: Mostrar informações de colisão
	print("Portal - collision_layer: ", collision_layer)
	print("Portal - collision_mask: ", collision_mask)
	
	# Conectar sinal de corpo entrando
	body_entered.connect(_on_body_entered)
	print("Portal: Sinal body_entered conectado")
	
	# Configurar partículas (se existirem)
	if has_node("Particles"):
		$Particles.emitting = true
		print("Portal: Partículas ativadas")

func _process(delta):
	time += delta
	
	# Rotação suave
	rotate_y(deg_to_rad(rotation_speed) * delta)
	
	# Movimento vertical (flutuação)
	var bob_offset = sin(time * bob_speed) * bob_height
	position.y = original_y + bob_offset
	
	# Pulsação da luz (se existir)
	if has_node("Light"):
		var light_intensity = 3.0 + sin(time * 2.0) * 2.0
		$Light.light_energy = light_intensity

func _on_body_entered(body):
	print("Portal: Corpo detectado!")
	print("  Tipo: ", body.get_class())
	print("  Nome: ", body.name)
	print("  Está no grupo 'player'? ", body.is_in_group("player"))
	print("  Grupos: ", body.get_groups())
	
	# Verificar se é o jogador
	if body.is_in_group("player"):
		print("🎉 Jogador entrou no portal! Fase concluída!")
		player_entered_portal.emit()
		
		# Efeitos visuais ao pegar o portal
		play_collect_effects()
		
		# Desabilitar colisão para evitar múltiplos triggers
		if has_node("CollisionShape3D"):
			$CollisionShape3D.disabled = true
	else:
		print("⚠️ Corpo detectado mas não é jogador!")

func play_collect_effects():
	print("Portal: Iniciando efeitos de coleta")
	
	# Aumentar partículas (se existirem)
	if has_node("Particles"):
		$Particles.amount = 200
		$Particles.speed_scale = 2.0
		$Particles.explosiveness = 1.0
	
	# Aumentar luz (se existir)
	if has_node("Light"):
		$Light.light_energy = 15.0
	
	# Fazer o portal desaparecer gradualmente
	if has_node("MeshInstance3D"):
		var tween = create_tween()
		tween.tween_property($MeshInstance3D, "scale", Vector3.ZERO, 0.8)
		tween.tween_callback(queue_free)