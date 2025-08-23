extends Sprite2D

@export var speed: float = 150.0  # pixels por segundo

func _process(delta):
	position.x += speed * delta
	if position.x > get_viewport_rect().size.x + texture.get_size().x:
		position.x = -texture.get_size().x  # volta pro começo
