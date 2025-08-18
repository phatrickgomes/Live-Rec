extends Control

@export var tempo_visivel: float = 3.0
@export var tempo_antes: float = 1.0   
@export var duracao_fade: float = 0.5  

func _ready():
	# começa invisível
	modulate.a = 0.0
	visible = false
	await get_tree().create_timer(tempo_antes).timeout
	mostrar_tutorial()

func mostrar_tutorial():
	visible = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, duracao_fade) 
	await get_tree().create_timer(tempo_visivel).timeout
	esconder_tutorial()

func esconder_tutorial():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duracao_fade)
	await tween.finished
	visible = false
