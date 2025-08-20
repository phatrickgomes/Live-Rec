extends CharacterBody2D
@onready var anima = $AnimationPlayer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var oxigenio = $ProgressBar
var tempo_regeneracao = 0.0
var intervalo_regeneracao = 0.8  ##intervalo da regeneraçao de stamina

func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	

func _physics_process(delta: float) -> void:
	move_and_slide()
	
	##regeneracao de stamina
	tempo_regeneracao += delta
	if tempo_regeneracao >= intervalo_regeneracao:
		tempo_regeneracao = 0.0
		regenerar_folego(10)  ##regenera 10% a cada segundo

func _input(event):
	if event.is_action_pressed("tiro") and anim.animation != "direto":
		if oxigenio.value > 0:
			anim.play("direto")
			anima.play("porrada")
			# Reduz 10% do folego
			reduzir_folego(10)
		else:
			print("sem folego")
	elif event.is_action_pressed("socojab") and anim.animation != "jab":
		##verifica se tem folego
		if oxigenio.value > 0:
			anim.play("jab")
			anima.play("porrada")
			##reduz 10% do folego
			reduzir_folego(10)
		else:
			print("sem folego")

##reduzir o folego
func reduzir_folego(percentual: float):
	var reducao = oxigenio.max_value * (percentual / 100.0)
	oxigenio.value = max(0, oxigenio.value - reducao)

##Funcao para recuperar o folego
func regenerar_folego(percentual: float):
	var regeneracao = oxigenio.max_value * (percentual / 100.0)
	oxigenio.value = min(oxigenio.max_value, oxigenio.value + regeneracao)

func _on_animation_finished():
	if anim.animation == "direto" or anim.animation == "jab":
		anim.play("idle")
