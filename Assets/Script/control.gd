extends Control

@onready var sub_viewport: SubViewport = $".."

var labirinto = preload("res://Assets/Scenes/labirinto.tscn")
var jamv = preload("res://Assets/Scenes/sprite_2d.tscn")
const MAIN_SCENE = ("res://Assets/Scenes/main_scene.tscn")

func _on_button_pressed() -> void:
	var player = PlayerManager.get_current_player()
	if player and player.objeto_selecionado != null and player.objeto_selecionado.is_in_group("fita"):
		for child in sub_viewport.get_children():
			child.queue_free()
		var maze_inst = labirinto.instantiate()
		sub_viewport.add_child(maze_inst)
	else:
		print("voce precisa da fita")

func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text == "JAMVITO":
		for child in sub_viewport.get_children():
			child.queue_free()
		var jamv_inst = jamv.instantiate()
		sub_viewport.add_child(jamv_inst)
		
		# Registrar o jogador interno
		var internal_player = jamv_inst.find_child("SparkyGlory")
		if internal_player:
			PlayerManager.register_internal_player(internal_player)
		else:
			printerr("Jogador interno não encontrado!")
		
		print("CESAR PATROCINA NOIS")

func _on_jogo_2_pressed():
	var player = PlayerManager.get_current_player()
	if player and player.objeto_selecionado != null and player.objeto_selecionado.is_in_group("fita"):
		for child in sub_viewport.get_children():
			child.queue_free()
	else:
		print("voce precisa da fita")

func _on_sair_do_jogo_pressed():
	PlayerManager.clear_internal_player()
	
	# Limpa a viewport
	for child in sub_viewport.get_children():
		child.queue_free()
	
	print("Saiu do jogo interno")
