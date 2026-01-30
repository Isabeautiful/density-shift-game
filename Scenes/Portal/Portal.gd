extends Area3D

signal player_entered_portal

@export var rotation_speed: float = 45.0
@export var bob_speed: float = 1.5
@export var bob_height: float = 0.3

var original_y: float
var time: float = 0.0

func _ready():
	original_y = position.y
	body_entered.connect(_on_body_entered)
	if has_node("Particles"):
		$Particles.emitting = true

func _process(delta):
	time += delta
	rotate_y(deg_to_rad(rotation_speed) * delta)
	var bob_offset = sin(time * bob_speed) * bob_height
	position.y = original_y + bob_offset
	if has_node("Light"):
		var light_intensity = 3.0 + sin(time * 2.0) * 2.0
		$Light.light_energy = light_intensity

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_entered_portal.emit()
		play_collect_effects()
		if has_node("CollisionShape3D"):
			$CollisionShape3D.disabled = true

func play_collect_effects():
	if has_node("Particles"):
		$Particles.amount = 200
		$Particles.speed_scale = 2.0
		$Particles.explosiveness = 1.0
	if has_node("Light"):
		$Light.light_energy = 15.0
	if has_node("MeshInstance3D"):
		var tween = create_tween()
		tween.tween_property($MeshInstance3D, "scale", Vector3.ZERO, 0.8)
		tween.tween_callback(queue_free)