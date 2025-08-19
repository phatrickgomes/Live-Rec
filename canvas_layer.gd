extends CanvasLayer

@export var volante: Sprite2D
@export var mao: Sprite2D
@export var angulo_maximo_volante: float = 90.0
@export var angulo_maximo_mao: float = 30.0
@export var suavizacao: float = 8.0
@export var movimento_lateral: float = 3.0
@export var tremor_intensidade: float = 0.5
@export var tamanho_base_mao: float = 2.4
@export var efeito_escala_curva: float = 0.05
@export var posicao_vertical_mao: float = 430.0  # Novo: controle da posição vertical

var rotacao_alvo: float = 0.0
var input_anterior: float = 0.0

func _ready():
	# Aplica o tamanho base e posição inicial
	mao.scale = Vector2(tamanho_base_mao, tamanho_base_mao)
	mao.position.y = posicao_vertical_mao  # Define a posição vertical

func _process(delta):
	# Obtém input horizontal
	var direcao = Input.get_axis("esquerda", "direita")
	
	# Calcula a velocidade de virada
	var velocidade_virada = (direcao - input_anterior) / delta
	input_anterior = direcao
	
	# Rotação principal do volante
	rotacao_alvo = direcao * angulo_maximo_volante
	volante.rotation_degrees = lerp(volante.rotation_degrees, rotacao_alvo, delta * suavizacao)
	
	# Animação da mão
	mao.rotation_degrees = -rotacao_alvo * -0.3
	mao.position.x = (direcao * movimento_lateral) + 420
	mao.position.y = posicao_vertical_mao  # Mantém a posição vertical
	
	# Efeitos adicionais
	adicionar_efeitos_extras(direcao, velocidade_virada, delta)

func adicionar_efeitos_extras(direcao: float, velocidade: float, delta: float):
	# Efeito de tremor
	var tremor = sin(Time.get_ticks_msec() * 0.05) * tremor_intensidade * abs(velocidade) * 0.01
	mao.rotation_degrees += tremor
	
	# Pequeno atraso no retorno ao centro
	if abs(direcao) < 0.1:
		mao.rotation_degrees = lerp(mao.rotation_degrees, 0.0, delta * suavizacao * 0.5)
		mao.position.x = lerp(mao.position.x, 380.0, delta * suavizacao * 0.5)
	
	# Ajuste de escala
	var escala = tamanho_base_mao + abs(direcao) * efeito_escala_curva
	mao.scale = Vector2(escala, escala)
