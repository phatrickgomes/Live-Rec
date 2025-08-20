extends CharacterBody2D

### CONFIGURAÇÕES ###
var velocidade_normal = 200
var velocidade_corrida = 350
var velocidade_atual = velocidade_normal
var forca_dash = 800
var duracao_dash = 0.2
var tempo_recarga_dash = 1.0
var desaceleracao = 15
var gravidade = 980  # Adicionando gravidade

var pode_dash = true
var esta_dashando = false
var esta_correndo = false
var esta_conjurando = false
var velocidade_dash = Vector2.ZERO  # Velocidade específica do dash

### NODES ###
@onready var animated_sprite = $AnimatedSprite2D
@onready var dash_timer = $DashTimer
@onready var dash_recarga_timer = $DashRecargaTimer
@onready var conjuracao_timer = $ConjuracaoTimer

func _ready():
	dash_timer.wait_time = duracao_dash
	dash_timer.one_shot = true
	dash_recarga_timer.wait_time = tempo_recarga_dash
	dash_recarga_timer.one_shot = true
	conjuracao_timer.one_shot = true
	
	# Conectar os sinais dos timers
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	dash_recarga_timer.timeout.connect(_on_dash_recarga_timer_timeout)
	conjuracao_timer.timeout.connect(_on_conjuracao_timer_timeout)

func _physics_process(delta):
	# Aplicar gravidade sempre, exceto durante o dash
	if not esta_dashando and not is_on_floor():
		velocity.y += gravidade * delta
	elif is_on_floor():
		velocity.y = 0
	
	if esta_conjurando:
		velocity.x = 0  # Apenas zera o movimento horizontal durante conjuração
	elif esta_dashando:
		# Durante o dash, manter a velocidade definida
		velocity = velocidade_dash
		move_and_slide()
		return
	else:
		processar_movimento(delta)
	
	processar_animacoes()
	move_and_slide()

func processar_movimento(delta):
	var direcao = Vector2.ZERO
	
	# Movimento horizontal
	if Input.is_action_pressed("direita"):
		direcao.x += 1
	if Input.is_action_pressed("esquerda"):
		direcao.x -= 1
	
	# Correr (Shift)
	esta_correndo = Input.is_action_pressed("Run")
	velocidade_atual = velocidade_corrida if esta_correndo else velocidade_normal
	
	# Aplicar movimento horizontal
	if direcao != Vector2.ZERO:
		velocity.x = lerp(velocity.x, direcao.x * velocidade_atual, desaceleracao * delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, desaceleracao * delta)
	
	# Virar sprite baseado na direção
	if direcao.x != 0:
		animated_sprite.flip_h = direcao.x < 0

func processar_animacoes():
	if esta_conjurando:
		if animated_sprite.animation != "summon":
			animated_sprite.play("summon")
	elif esta_dashando:
		if animated_sprite.animation != "dash":
			animated_sprite.play("dash")
	elif abs(velocity.x) > 10:
		if esta_correndo:
			if animated_sprite.animation != "run":
				animated_sprite.play("run")
		else:
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func _input(event):
	# Dash com botão esquerdo do mouse
	if event.is_action_pressed("DashAttack") and pode_dash and not esta_conjurando and is_on_floor():
		iniciar_dash()
	
	# Conjuração com botão direito do mouse
	if event.is_action_pressed("Summon") and not esta_dashando and is_on_floor():
		iniciar_conjuracao()

func iniciar_dash():
	esta_dashando = true
	pode_dash = false
	
	# Direção do dash baseada na posição do mouse
	var mouse_pos = get_global_mouse_position()
	var direcao = (mouse_pos - global_position).normalized()
	
	# Garantir que o dash seja principalmente horizontal
	direcao.y *= 0.3  # Reduzir componente vertical
	
	velocidade_dash = direcao * forca_dash
	animated_sprite.play("dash")
	
	dash_timer.start()
	dash_recarga_timer.start()

func iniciar_conjuracao():
	esta_conjurando = true
	animated_sprite.play("summon")
	
	# Duração da animação de conjuração
	conjuracao_timer.wait_time = 1.0
	conjuracao_timer.start()

func _on_dash_timer_timeout():
	esta_dashando = false
	# Manter apenas parte da velocidade horizontal após o dash
	velocity.x = velocidade_dash.x * 0.3
	velocidade_dash = Vector2.ZERO

func _on_dash_recarga_timer_timeout():
	pode_dash = true

func _on_conjuracao_timer_timeout():
	esta_conjurando = false
