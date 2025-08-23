extends CanvasLayer

@export var volante: Sprite2D
@export var mao: Sprite2D
@export var carro: Sprite2D  
@export var angulo_maximo_volante: float = 90.0
@export var angulo_maximo_mao: float = 30.0
@export var suavizacao: float = 8.0
@export var movimento_lateral: float = 3.0
@export var tremor_intensidade: float = 0.5
@export var tamanho_base_mao: float = 2.4
@export var efeito_escala_curva: float = 0.05
@export var posicao_vertical_mao: float = 432.0


@export var tremor_carro_intensidade: float = 3.0
@export var tremor_carro_velocidade: float = 5.0
@export var tremor_carro_rotacao: float = 1.5  

var rotacao_alvo: float = 0.0
var input_anterior: float = 0.0
var tempo_tremor: float = 0.0
var posicao_original_carro: Vector2

func _ready():
	mao.scale = Vector2(tamanho_base_mao, tamanho_base_mao)
	mao.position.y = posicao_vertical_mao
	posicao_original_carro = carro.position 

func _process(delta):
	var direcao = Input.get_axis("esquerda", "direita")
	
	var velocidade_virada = (direcao - input_anterior) / delta
	input_anterior = direcao
	
	rotacao_alvo = direcao * angulo_maximo_volante
	volante.rotation_degrees = lerp(volante.rotation_degrees, rotacao_alvo, delta * suavizacao)
	
	mao.rotation_degrees = -rotacao_alvo * -0.3
	mao.position.x = (direcao * movimento_lateral) + 90.0
	mao.position.y = posicao_vertical_mao
	
	# Aplica efeitos de tremor no carro
	aplicar_tremor_carro(delta)
	
	adicionar_efeitos_extras(direcao, velocidade_virada, delta)

func aplicar_tremor_carro(delta):
	tempo_tremor += delta * tremor_carro_velocidade

	var tremor_x = sin(tempo_tremor * 1.7) * tremor_carro_intensidade
	var tremor_y = cos(tempo_tremor * 1.3) * tremor_carro_intensidade
	var tremor_rot = sin(tempo_tremor * 2.1) * tremor_carro_rotacao
	

	carro.position = posicao_original_carro + Vector2(tremor_x, tremor_y)
	carro.rotation_degrees = tremor_rot

func adicionar_efeitos_extras(direcao: float, velocidade: float, delta: float):
	var tremor = sin(Time.get_ticks_msec() * 0.05) * tremor_intensidade * abs(velocidade) * 0.01
	mao.rotation_degrees += tremor
	
	if abs(direcao) < 0.1:
		mao.rotation_degrees = lerp(mao.rotation_degrees, 0.0, delta * suavizacao * 0.5)
		mao.position.x = lerp(mao.position.x, 380.0, delta * suavizacao * 0.5)
	
	var escala = tamanho_base_mao + abs(direcao) * efeito_escala_curva
	mao.scale = Vector2(escala, escala)
