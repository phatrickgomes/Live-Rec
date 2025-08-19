extends Node3D
@export var speed := 30.0

func _process(delta: float) -> void:
	translate(Vector3(0, 0, speed * delta))
	if position.z > 100:
		queue_free()
