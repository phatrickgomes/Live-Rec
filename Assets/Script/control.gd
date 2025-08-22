extends Control

@onready var sub_viewport
var labirinto = preload("res://Assets/Scenes/labirinto.tscn")
var jamv = preload("res://Assets/Scenes/sprite_2d.tscn")
var jogo2d = preload("res://Assets/Scenes/Memories of Zerous.tscn")
var jamv_truck = preload("res://jamv_truck.tscn")
const JAMV_CHUPETAO = preload("res://jamv_chupetao.tscn")
var fight_music = preload("res://fight_music.tscn")

@onready var error_label: Label = $Label
@export var blink_times := 6
@export var blink_duration := 0.3

func _ready() -> void:
	Global.Lurdes_vida = 3
	Global.Vida_jamv = 3
	if get_parent() != null:
		sub_viewport = get_parent()
	blink_label()

func blink_label() -> void:
	var visible := true
	for i in blink_times:
		error_label.visible = visible
		visible = !visible
		await get_tree().create_timer(blink_duration).timeout
	error_label.visible = false


func _on_button_pressed() -> void:
	var player = PlayerManager.get_current_player()
	if player and player.objeto_selecionado != null and player.objeto_selecionado.is_in_group("fita"):
		for child in sub_viewport.get_children():
			child.queue_free()
		var maze_inst = labirinto.instantiate()
		sub_viewport.add_child(maze_inst)
		Global.chat_on = true
	else:
		print("voce precisa da fita")

func _on_line_edit_text_submitted(new_text: String) -> void:
	if new_text == "JAMVITO":
		for child in sub_viewport.get_children():
			child.queue_free()
		var jamv_inst = jamv.instantiate()
		sub_viewport.add_child(jamv_inst)
		var internal_player = jamv_inst.find_child("SparkyGlory")
		if internal_player:
			PlayerManager.register_internal_player(internal_player)
			Global.chat_on = true
		else:
			printerr("Jogador interno não encontrado!")
		print("CESAR PATROCINA NOIS")

func _on_jogo_2_pressed():
	var player = PlayerManager.get_current_player()
	if player and player.objeto_selecionado != null and player.objeto_selecionado.is_in_group("fita"):
		for child in sub_viewport.get_children():
			child.queue_free()
		var maze_inst = jogo2d.instantiate()
		sub_viewport.add_child(maze_inst)
		Global.chat_on = true
	else:
		print("voce precisa da fita")

func _on_sair_do_jogo_pressed():
	PlayerManager.clear_internal_player()
	for child in sub_viewport.get_children():
		child.queue_free()
	print("Saiu do jogo interno")
	Global.Ta_no_jogo = false

func _on_line_edit_text_changed(new_text):
	if new_text == "jamv_chupetao":
		for child in sub_viewport.get_children():
			child.queue_free()
		var jamv_inst = JAMV_CHUPETAO.instantiate()
		sub_viewport.add_child(jamv_inst)
		Global.chat_on = true
		var internal_player = jamv_inst.find_child("SparkyGlory")
		if internal_player:
			PlayerManager.register_internal_player(internal_player)
			
		else:
			printerr("Jogador interno não encontrado!")
		print("CESAR PATROCINA NOIS")

func jamv_truck_submitted(new_text):
	if new_text == "jamv_truck":
		for child in sub_viewport.get_children():
			child.queue_free()
		var jamv_inst = jamv_truck.instantiate()
		sub_viewport.add_child(jamv_inst)
		Global.chat_on = true
		var internal_player = jamv_inst.find_child("SparkyGlory")
		if internal_player:
			PlayerManager.register_internal_player(internal_player)
			
		else:
			printerr("Jogador interno não encontrado!")
		print("CESAR PATROCINA NOIS")

func Fight_music_submitted(new_text):
	if new_text == "night_terror":
		for child in sub_viewport.get_children():
			child.queue_free()
		var fight_inst = fight_music.instantiate()
		sub_viewport.add_child(fight_inst)
		Global.chat_on = true
		var internal_player = fight_inst.find_child("SparkyGlory")
		if internal_player:
			PlayerManager.register_internal_player(internal_player)
		else:
			printerr("Jogador interno não encontrado!")
		print("CESAR PATROCINA NOIS")
