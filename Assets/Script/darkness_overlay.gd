extends ColorRect

@onready var shader_material: ShaderMaterial = material
var current_darkness: float = 0.0

func _ready():
	# Configura a textura da tela no shader
	shader_material.set_shader_parameter("screen_texture", get_viewport().get_texture())
	shader_material.set_shader_parameter("darkness_amount", 0.0)
	shader_material.set_shader_parameter("vignette_strength", 0.8)
	shader_material.set_shader_parameter("dark_color", Color(0, 0, 0, 0.7))
	current_darkness = 0.0

func set_darkness(amount: float):
	current_darkness = amount
	shader_material.set_shader_parameter("darkness_amount", amount)

func fade_in(duration: float = 1.5):
	var tween = create_tween()
	tween.tween_method(set_darkness, current_darkness, 0.8, duration)

func fade_out(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_method(set_darkness, current_darkness, 0.0, duration)

func start_horror_pulse():
	var pulse_tween = create_tween()
	pulse_tween.tween_method(set_darkness, 0.7, 0.9, 1.2)
	pulse_tween.tween_method(set_darkness, 0.9, 0.7, 1.2)
	current_darkness = 0.7
