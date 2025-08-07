extends Control

@onready var sub_viewport: SubViewport = $".."
var labirinto = preload("res://labrinto.tscn")

func _on_button_pressed() -> void:
	for child in sub_viewport.get_children():
		child.queue_free()
	var new_scene = labirinto.instantiate()
	sub_viewport.add_child(new_scene)
