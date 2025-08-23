extends Sprite2D

@export var speed: float = 50.0  

func _process(delta):
	position.x += speed * delta
	if position.x > get_viewport_rect().size.x + texture.get_size().x:
		position.x = -texture.get_size().x
