extends MeshInstance3D

@export var speed := 20.0  # Velocidade do movimento

func _process(delta):
	translate(Vector3(0, 0, -speed * delta))  # Move no eixo Z
