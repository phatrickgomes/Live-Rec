extends Node

# Sistema de gerenciamento de jogadores
var jogador_principal: Node = null
var jogador_interno: Node = null

func register_main_player(player: Node):
	jogador_principal = player
	print("Jogador principal registrado: ", player.name)

func register_internal_player(player: Node):
	jogador_interno = player
	print("Jogador interno registrado: ", player.name)

func get_current_player() -> Node:
	if Global.Ta_no_jogo and jogador_interno != null:
		return jogador_interno
	return jogador_principal

func clear_internal_player():
	jogador_interno = null
	print("Jogador interno removido")

# Depuração
func _process(delta):
	if Input.is_key_pressed(KEY_F12):
		print("=== Estado do PlayerManager ===")
		print("Jogador Principal: ", jogador_principal.name if jogador_principal else "Nenhum")
		print("Jogador Interno: ", jogador_interno.name if jogador_interno else "Nenhum")
		print("Global.Ta_no_jogo: ", Global.Ta_no_jogo)
