extends CharacterBody2D

enum Estado { PATRULHA, STALKING, TRANSFORMACAO, PERSEGUICAO }

### CONFIGURAÇÕES PRINCIPAIS ###
var estado_atual: Estado = Estado.PATRULHA
var jogador = null  # Referência fraca ao jogador
var tempo_stalking = 5  # Tempo em segundos
var velocidade_perseguicao = 80
var patrol_speed = 40
var acceleration = 20.0
var gravity = 1200
var is_on_floor = false

### NODES ###
@onready var timer_fuga = $Icon/Visao/TimerFuga
@onready var timer_transformacao = $TimerTransformacao

@onready var path_follow: PathFollow2D = $Path2D/PathFollow2D

@onready var visao = $Icon/Visao
@onready var darkness_overlay: ColorRect = $"../ShaderEffects/DarknessOverlay"
### SISTEMA DE ÁUDIO SINCRONIZADO ###
@onready var audio_players = {
	"stalking": $TrilhaStalking,
	"rugido": $RugidoWendigo,
	"perseguicao": $TrilhaPerseguicao
}

func _ready():
	# Configura timers
	timer_fuga.wait_time = tempo_stalking
	timer_fuga.one_shot = true
	timer_transformacao.one_shot = true
	timer_transformacao.wait_time = 0.1

	# Configura volumes iniciais (opcional)
	audio_players["rugido"].volume_db = 0      # Volume máximo
	audio_players["perseguicao"].volume_db = -5  # Levemente mais baixo

### FÍSICA E MOVIMENTO ###
func _physics_process(delta):
	# Gravidade
	if not is_on_floor:
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	# Lógica de estados
	match estado_atual:
		Estado.PATRULHA:
			patrulhar(delta)
		Estado.STALKING:
			stalkear_jogador()
		Estado.PERSEGUICAO:
			if jogador_eh_visivel():
				perseguir_jogador(delta)
			else:
				retornar_patrulha()
	
	move_and_slide()

### COMPORTAMENTOS ###
func patrulhar(delta):
	path_follow.progress += patrol_speed * delta
	var direction = (path_follow.global_position - global_position).normalized()
	velocity = direction * patrol_speed

func stalkear_jogador():
	velocity = Vector2.ZERO  # Fica parado

func perseguir_jogador(delta):
	var jogador_ref = jogador.get_ref()
	if jogador_ref and is_instance_valid(jogador_ref):
		var direcao = (jogador_ref.global_position - global_position).normalized()
		var target_velocity = direcao * velocidade_perseguicao
		velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)

func jogador_eh_visivel() -> bool:
	if jogador == null: return false
	var jogador_ref = jogador.get_ref()
	if jogador_ref == null or not is_instance_valid(jogador_ref): return false
	
	for body in visao.get_overlapping_bodies():
		if body.name == "SparkyGlory":
			return true
	return false

### SISTEMA DE ÁUDIO ###
func iniciar_transformacao():
	estado_atual = Estado.TRANSFORMACAO
	
	# Para a trilha de stalking e inicia rugido + perseguição SIMULTANEAMENTE
	audio_players["stalking"].stop()
	audio_players["rugido"].play()
	audio_players["perseguicao"].play()
	
	# Espera o rugido terminar antes de confirmar a perseguição
	await audio_players["rugido"].finished
	estado_atual = Estado.PERSEGUICAO
	print("Perseguição iniciada com sincronia perfeita!")

func retornar_patrulha():
	estado_atual = Estado.PATRULHA
	audio_players["perseguicao"].stop()
	if darkness_overlay:
		darkness_overlay.fade_out(0.5)
	jogador = null

### SINAIS ###
func _on_visao_body_entered(body):
	if body.name == "SparkyGlory" and estado_atual == Estado.PATRULHA:
		jogador = weakref(body)
		estado_atual = Estado.STALKING
		audio_players["stalking"].play()
		timer_fuga.start()
		if darkness_overlay:
			darkness_overlay.fade_in()

func _on_visao_body_exited(body):
	if body.name == "SparkyGlory" and estado_atual == Estado.STALKING:
		estado_atual = Estado.PATRULHA
		audio_players["stalking"].stop()
		if darkness_overlay:
			darkness_overlay.fade_out(0.5)
		jogador = null

func _on_timer_fuga_timeout():
	if estado_atual == Estado.STALKING:
		if darkness_overlay:
			darkness_overlay.start_horror_pulse()
		iniciar_transformacao()  # Chamada sincronizada
