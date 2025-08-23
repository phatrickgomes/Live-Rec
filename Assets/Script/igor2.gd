extends Sprite2D
@export var speed: float = 150.0 


func _process(delta):
	position.x -= speed * delta  # subtrai para ir para a esquerda
	if position.x < -texture.get_size().x:
		position.x = get_viewport_rect().size.x  # volta pro começo
