extends CharacterBody2D

@export var speed: float = 600
var direction = Vector2.RIGHT 

func set_direction(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()


func _on_area_2d_area_entered(area):
	if area.is_in_group("jamv"):
		queue_free()
