# Para os obstáculos (adicione este script a eles)
extends RigidBody3D

var speed = 20.0  # Deve corresponder ao forward_speed do jogador

func _physics_process(delta):
	position.z -= speed * delta
	if position.z < -20:  # Destruir obstáculos que passaram
		queue_free()
