extends CharacterBody3D

@export var speed := 20.0

func _physics_process(delta: float) -> void:
	var direction = Vector3.ZERO
	
	if Input.is_action_pressed("ui_left"): 
		direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		direction.x += 1

	velocity = direction * speed
	move_and_slide()
