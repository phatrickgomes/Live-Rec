extends Node3D
@export var speed := 90.0

func _ready():
	add_to_group("arvores")

func _process(delta: float) -> void:
	translate(Vector3(0, 0, speed * delta))
	if position.z > 1000:
		queue_free()
