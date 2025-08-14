extends Control

@onready var sub_viewport: SubViewport = $".."
var labirinto = preload("res://labirinto.tscn")
var jamv = preload("res://sprite_2d.tscn")

func _on_button_pressed() -> void:
	var player = get_tree().get_root().get_node("quarto/SparkyGlory")
	if player.objeto_selecionado != null and player.objeto_selecionado.is_in_group("fita"):
		for child in sub_viewport.get_children():
			child.queue_free()
		var maze_inst = labirinto.instantiate()
		sub_viewport.add_child(maze_inst)
		Global.Ta_no_jogo = true
	else:
		print("voce precisa da fita")

func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text == "JAMV":
		var jamv_inst = jamv.instantiate()
		sub_viewport.add_child(jamv_inst)
		print("CESAR PATROCINA NOIS")
