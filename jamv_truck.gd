extends CharacterBody3D

@export var max_forward_speed := 60.0  
@export var forward_acceleration := 20.0 
@export var side_speed := 50.0         

var forward_velocity := 0.0

func _physics_process(delta: float) -> void:
	forward_velocity = clamp(forward_velocity + forward_acceleration * delta, 0, max_forward_speed)

	var direction = Vector3.ZERO

	# Controles laterais
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1


	velocity.x = direction.x * side_speed
	velocity.z = -forward_velocity 

	move_and_slide()
