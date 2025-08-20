extends CharacterBody2D
@onready var anima = $AnimationPlayer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var oxigenio = $ProgressBar
var tempo_regeneracao = 0.0
var intervalo_regeneracao = 4  ##intervalo da regeneraçao de stamina
var tempo_soco = true

var posicao_original = 0


var vida = 4

@onready var vida_lab = $vida



func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	

func _physics_process(delta: float) -> void:
	move_and_slide()
	
	##regeneracao de stamina
	tempo_regeneracao += delta
	if tempo_regeneracao >= intervalo_regeneracao:
		tempo_regeneracao = 0.0
		regenerar_folego(30)  ##regenera 10% a cada segundo

func _input(event):
	if event.is_action_pressed("tiro") and anim.animation != "direto" and tempo_soco == true:
		if oxigenio.value > 0:
			anim.play("direto")
			anima.play("porrada")
			$"../inimigo".desviar()
			$tempo_soco.start()
			tempo_soco = false
			# Reduz 10% do folego
			reduzir_folego(10)
		else:
			print("sem folego")
	elif event.is_action_pressed("socojab") and anim.animation != "jab" and tempo_soco == true:
		##verifica se tem folego
		if oxigenio.value > 0:
			anim.play("jab")
			$"../inimigo".desviar()
			$tempo_soco.start()
			tempo_soco = false
			anima.play("porrada")
			##reduz 10% do folego
			reduzir_folego(10)
		else:
			print("sem folego")


	elif event.is_action_pressed("jump"):
		if oxigenio.value > 0:
			posicao_original = position.x
			var direcao_esquiva = -1
			velocity.x = direcao_esquiva * 70
			anim.play("desvio")
			anima.play("esquiva")
			reduzir_folego(10)
			await anim.animation_finished
			velocity.x = 0
			var tween = create_tween()
			tween.tween_property(self, "position:x", posicao_original, 0.2)
			anim.play("idle")

##reduzir o folego
func reduzir_folego(percentual: float):
	var reducao = oxigenio.max_value * (percentual / 100.0)
	oxigenio.value = max(0, oxigenio.value - reducao)

##Funcao para recuperar o folego
func regenerar_folego(percentual: float):
	var regeneracao = oxigenio.max_value * (percentual / 100.0)
	oxigenio.value = min(oxigenio.max_value, oxigenio.value + regeneracao)

func _on_animation_finished():
	if anim.animation == "direto" or anim.animation == "jab" or anim.animation == "desvio":
		anim.play("idle")


func levar_dano(dano: int) -> void:
	vida -= dano
	if vida < 0:
		vida = 0
	atualizar_vida_hud()
	if vida <= 0:
		morrer()




func morrer() -> void:
	print("voce morreu")
	queue_free()  

func atualizar_vida_hud():
	if vida_lab:
		vida_lab.text = str(vida)

func _on_timer_timeout() -> void:
	tempo_soco = true	


func _on_hurt_area_entered(area):
	if area.is_in_group("soco_inimigo"):
		print("tomando dano")
		levar_dano(1)
