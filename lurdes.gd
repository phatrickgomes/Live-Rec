extends CharacterBody2D

@onready var anima: AnimationPlayer = $AnimationPlayer
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var oxigenio: ProgressBar = $"../ProgressBar"
@onready var vida_lab: Label = $"../vida"

var tempo_regeneracao: float = 0.0
var intervalo_regeneracao: float = 4.0
var tempo_soco: bool = true
var posicao_original: float = 0.0
var vida: int = 4

## maquina de estados
enum Estado {IDLE, ATACANDO, ESQUIVANDO, DANO}
var estado_atual: Estado = Estado.IDLE


var tempo_dano: float = 0.0
var duracao_dano: float = 0.40 
func _ready():
	randomize()
	anim.animation_finished.connect(_on_animation_finished)
	atualizar_vida_hud()

func _physics_process(delta: float) -> void:
	move_and_slide()
	
	## regeneração de stamina
	tempo_regeneracao += delta
	if tempo_regeneracao >= intervalo_regeneracao:
		tempo_regeneracao = 0.0
		regenerar_folego(30)

	## controle do estado de dano
	if estado_atual == Estado.DANO:
		tempo_dano -= delta
		if tempo_dano <= 0.0:
			estado_atual = Estado.IDLE
			anim.play("idle")

func _input(event):
	## só reage ao input se estiver em IDLE
	if estado_atual == Estado.IDLE:
		if event.is_action_pressed("tiro") and tempo_soco:
			if oxigenio.value > 0:
				estado_atual = Estado.ATACANDO
				anim.play("direto")
				anima.play("porrada")
				$"../inimigo".desviar()
				$tempo_soco.start()
				tempo_soco = false
				reduzir_folego(20)
			else:
				print("sem folego")
		elif event.is_action_pressed("socojab") and tempo_soco:
			if oxigenio.value > 0:
				estado_atual = Estado.ATACANDO
				anim.play("jab")
				anima.play("porrada")
				$"../inimigo".desviar()
				$tempo_soco.start()
				tempo_soco = false
				reduzir_folego(20)
			else:
				print("sem folego")
		elif event.is_action_pressed("jump"):
			if oxigenio.value > 0:
				estado_atual = Estado.ESQUIVANDO
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
				await tween.finished
				estado_atual = Estado.IDLE
				anim.play("idle")

func _on_animation_finished():
	if estado_atual == Estado.ATACANDO:
		estado_atual = Estado.IDLE
		anim.play("idle")
	elif estado_atual == Estado.ESQUIVANDO:
		pass

## Sistema de fôlego
func animar_barra(valor_alvo: float, duracao: float = 0.3):
	var tween = create_tween()
	tween.tween_property(oxigenio, "value", valor_alvo, duracao).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func reduzir_folego(percentual: float):
	var reducao = oxigenio.max_value * (percentual / 100.0)
	var novo_valor = max(0, oxigenio.value - reducao)
	animar_barra(novo_valor)

func regenerar_folego(percentual: float):
	var regeneracao = oxigenio.max_value * (percentual / 100.0)
	var novo_valor = min(oxigenio.max_value, oxigenio.value + regeneracao)
	animar_barra(novo_valor)

## vida
func levar_dano(dano: int) -> void:
	vida -= dano
	if vida < 0:
		vida = 0
	atualizar_vida_hud()

	##entra em estado de DANO curto
	if vida > 0:
		estado_atual = Estado.DANO
		tempo_dano = duracao_dano
		anim.play("hit")     #animação de hit do sprite
	if vida <= 0:
		morrer()

func atualizar_vida_hud():
	if vida_lab:
		vida_lab.text = str(vida)

func morrer() -> void:
	print("voce morreu")
	get_tree().reload_current_scene()

##timer soco
func _on_timer_timeout() -> void:
	tempo_soco = true

##quando inimigo acerta
func _on_hurt_area_entered(area):
	if area.is_in_group("soco_inimigo"):
		print("tomando dano")
		levar_dano(1)
