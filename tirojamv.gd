extends CharacterBody2D

@export var speed: float = 700
var direction = Vector2.LEFT 

func _ready():

	var x = randf() * -4.0       
	var y = randf() * 2 - 1    
	direction = Vector2(x, y).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()



func _on_area_2d_area_entered(area):
	if area.is_in_group("chupetinha_player"):
		queue_free()
