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

enum Estado {IDLE, ATACANDO, ESQUIVANDO, DANO}
var estado_atual: Estado = Estado.IDLE

var duracao_dano: float = 0.40 
var esquiva_tween: Tween = null
var pode_esquivar: bool = false   # Flag para modo de esquiva obrigatória

func _ready():
	randomize()
	anim.animation_finished.connect(_on_animation_finished)
	atualizar_vida_hud()
	
	# Conectar ao inimigo para receber sinal de ataque
	var inimigo = $"../inimigo"
	if inimigo:
		inimigo.connect("atacando", Callable(self, "_on_inimigo_atacando"))


func _physics_process(delta: float) -> void:
	move_and_slide()
	
	tempo_regeneracao += delta
	if tempo_regeneracao >= intervalo_regeneracao:
		tempo_regeneracao = 0.0
		regenerar_folego(30)

func _input(event):
	# Se estiver no modo de esquiva obrigatória, só permite esquivar
	if estado_atual == Estado.IDLE or pode_esquivar:
		if event.is_action_pressed("jump") and oxigenio.value > 0:
			estado_atual = Estado.ESQUIVANDO
			posicao_original = position.x
			var direcao_esquiva = -1 if randi() % 2 == 0 else 1
			velocity.x = direcao_esquiva * 60
			anim.play("desvio")
			anima.play("esquiva")
			reduzir_folego(10)
			await anim.animation_finished
			velocity.x = 0
			esquiva_tween = create_tween()
			esquiva_tween.tween_property(self, "position:x", posicao_original, 0.2)
			await esquiva_tween.finished
			if estado_atual == Estado.ESQUIVANDO:
				estado_atual = Estado.IDLE
				anim.play("idle")
	
	# Se não está no modo de esquiva obrigatória, permite atacar normalmente
	if not pode_esquivar and estado_atual == Estado.IDLE:
		if event.is_action_pressed("tiro") and tempo_soco:
			if oxigenio.value > 0:
				estado_atual = Estado.ATACANDO
				anim.play("direto")
				anima.play("porrada")
				$"../inimigo".desviar()
				$tempo_soco.start()
				tempo_soco = false
				reduzir_folego(20)
		elif event.is_action_pressed("socojab") and tempo_soco:
			if oxigenio.value > 0:
				estado_atual = Estado.ATACANDO
				anim.play("jab")
				anima.play("porrada")
				$"../inimigo".desviar()
				$tempo_soco.start()
				tempo_soco = false
				reduzir_folego(20)

func _on_inimigo_atacando():
	# Ativa modo de esquiva obrigatória
	pode_esquivar = true
	await get_tree().create_timer(1.0).timeout  # espera 1 segundo
	pode_esquivar = false


func _on_animation_finished():
	if estado_atual == Estado.ATACANDO:
		await get_tree().create_timer(0.06).timeout
		estado_atual = Estado.IDLE
		anim.play("idle")
	elif estado_atual == Estado.ESQUIVANDO:
		pass

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

func levar_dano(dano: int) -> void:
	vida -= dano
	if vida < 0:
		vida = 0
	atualizar_vida_hud()

	if vida > 0:
		if esquiva_tween and esquiva_tween.is_running():
			esquiva_tween.kill()
		velocity.x = 0
		estado_atual = Estado.DANO
		anim.play("hit")
		await get_tree().create_timer(duracao_dano + 0.25).timeout
		if estado_atual == Estado.DANO:
			estado_atual = Estado.IDLE
			anim.play("idle")
	else:
		morrer()

func atualizar_vida_hud():
	if vida_lab:
		vida_lab.text = str(vida)

func morrer() -> void:
	print("voce morreu")
	get_tree().reload_current_scene()

func _on_timer_timeout() -> void:
	tempo_soco = true

func _on_hurt_area_entered(area):
	if area.is_in_group("soco_inimigo"):
		print("tomando dano")
		levar_dano(1)
