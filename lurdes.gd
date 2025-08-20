extends CharacterBody2D

@onready var anima: AnimationPlayer = $AnimationPlayer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var oxigenio: ProgressBar = $"../ProgressBar"
@onready var vida_lab: Label =  $"../vida" ## ajuste o caminho caso seu Label esteja dentro de CanvasLayer/HUD
var tempo_regeneracao: float = 0.0
var intervalo_regeneracao: float = 4.0  ## intervalo da regeneraçao de stamina
var tempo_soco: bool = true
var posicao_original: float = 0.0
var vida: int = 4

var esquivando: bool = false

func _ready():
	randomize()  
	anim.animation_finished.connect(_on_animation_finished)
	atualizar_vida_hud() 

func _physics_process(delta: float) -> void:
	move_and_slide()
	## regeneracao de stamina
	tempo_regeneracao += delta
	if tempo_regeneracao >= intervalo_regeneracao:
		tempo_regeneracao = 0.0
		regenerar_folego(30)  ## regenera 30% a cada intervalo

func _input(event):
	if event.is_action_pressed("tiro") and anim.animation != "direto" and tempo_soco == true:
		if oxigenio.value > 0:
			anim.play("direto")
			anima.play("porrada")
			$"../inimigo".desviar()
			$tempo_soco.start()
			tempo_soco = false
			reduzir_folego(20) ## Reduz 20% do fôlego
		else:
			print("sem folego")
	elif event.is_action_pressed("socojab") and anim.animation != "jab" and tempo_soco == true:
		if oxigenio.value > 0:
			anim.play("jab")
			$"../inimigo".desviar()
			$tempo_soco.start()
			tempo_soco = false
			anima.play("porrada")
			reduzir_folego(20) ## Reduz 20% do fôlego
		else:
			print("sem folego")
	elif event.is_action_pressed("jump"):
		if oxigenio.value > 0 and not esquivando:  # só esquiva se não estiver esquivando
			esquivando = true  # bloqueia novas esquivas
			posicao_original = position.x
			var direcao_esquiva = -1 if randi() % 2 == 0 else 1
			velocity.x = direcao_esquiva * 70
			anim.play("desvio")
			anima.play("esquiva")
			reduzir_folego(10)
			await anim.animation_finished
			velocity.x = 0
			var tween = create_tween()
			tween.tween_property(self, "position:x", posicao_original, 0.2)
			await tween.finished  # espera o tween terminar
			anim.play("idle")
			esquivando = false  # libera a esquiva

## Função para animar a barra de fôlego
func animar_barra(valor_alvo: float, duracao: float = 0.3):
	var tween = create_tween()
	tween.tween_property(oxigenio, "value", valor_alvo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

## reduzir o folego
func reduzir_folego(percentual: float):
	var reducao = oxigenio.max_value * (percentual / 100.0)
	var novo_valor = max(0, oxigenio.value - reducao)
	animar_barra(novo_valor)

## recuperar o folego
func regenerar_folego(percentual: float):
	var regeneracao = oxigenio.max_value * (percentual / 100.0)
	var novo_valor = min(oxigenio.max_value, oxigenio.value + regeneracao)
	animar_barra(novo_valor)

func _on_animation_finished():
	if anim.animation == "direto" or anim.animation == "jab" or anim.animation == "desvio":
		anim.play("idle")

## sistema de vida
func levar_dano(dano: int) -> void:
	vida -= dano
	if vida < 0:
		vida = 0
	atualizar_vida_hud()
	if vida <= 0:
		morrer()

func atualizar_vida_hud():
	if vida_lab:
		vida_lab.text = str(vida)

func morrer() -> void:
	print("voce morreu")
	queue_free()

## timer para soco
func _on_timer_timeout() -> void:
	tempo_soco = true

## quando inimigo acerta
func _on_hurt_area_entered(area):
	if area.is_in_group("soco_inimigo"):
		print("tomando dano")
		levar_dano(1)
