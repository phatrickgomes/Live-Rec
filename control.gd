extends Control

@onready var sub_viewport: SubViewport = $".."
var labirinto = preload("res://labrinto.tscn")
@onready var jamv: Control = $"."


func _on_button_pressed() -> void:
	var player = get_tree().get_root().get_node("quarto/player")
	if player.objeto_selecionado != null and player.objeto_selecionado.is_in_group("fita"):
		for child in sub_viewport.get_children():
			child.queue_free()
		var new_scene = labirinto.instantiate()
		sub_viewport.add_child(new_scene)
		Global.Ta_no_jogo = true
	else:
		print("voce precisa da fita")

func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text == "JAMV":
		get_tree().change_scene_to_file("res://sprite_2d.tscn")
		print("CESAR PATROCINA NOIS")
