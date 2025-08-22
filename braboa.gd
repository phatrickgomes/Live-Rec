extends CanvasLayer

@onready var imagem: Sprite2D = $"Img-20250708-wa0014~2"
@onready var som: AudioStreamPlayer = $toasy

@export var tempo_visivel: float = 2.0
@export var deslocamento: float = 300.0
@export var altura: float = 300.0
@export var parada_x: float = -500.0
@export_enum("direita", "esquerda") var direcao: String = "direita"
@export var chance_por_frame: float = 0.00001 
var apareceu: bool = false

func _ready():
	randomize()
	var tela = get_viewport().get_visible_rect().size
	if direcao == "direita":
		imagem.position = Vector2(tela.x + imagem.texture.get_width() + deslocamento, altura)
	else:
		imagem.position = Vector2(-imagem.texture.get_width() - deslocamento, altura)

func _process(delta):
	if apareceu:
		return
	
	if randf() <= chance_por_frame:
		apareceu = true
		mostrar()

func mostrar():
	som.play()
	var tela = get_viewport().get_visible_rect().size
	var destino_x: float
	
	if direcao == "direita":
		destino_x = tela.x - imagem.texture.get_width() - parada_x
	else:
		destino_x = parada_x
	
	var tween = create_tween()
	
	# entra
	tween.tween_property(
		imagem, "position:x",
		destino_x,
		0.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_interval(tempo_visivel)

	if direcao == "direita":
		tween.tween_property(
			imagem, "position:x",
			tela.x + imagem.texture.get_width() + deslocamento,
			0.5
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		tween.tween_property(
			imagem, "position:x",
			-imagem.texture.get_width() - deslocamento,
			0.5
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
