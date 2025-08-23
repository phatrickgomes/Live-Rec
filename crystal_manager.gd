extends Node

# configurações e estado
var purple_total: int = 0
var purple_collected: int = 0
var red_crystals: Array = []
var enemy_ref: Node = null

# ----- Registro -----
func register_purple(crystal: Node) -> void:
	# só soma total (evita duplicatas)
	purple_total += 1
	print("[CrystalManager] purple registered. total = ", purple_total)

func register_red_crystal(crystal: Node) -> void:
	if crystal not in red_crystals:
		red_crystals.append(crystal)
		crystal.visible = false
		print("[CrystalManager] red crystal registered and hidden.")

func register_enemy(enemy: Node) -> void:
	enemy_ref = enemy
	print("[CrystalManager] enemy registered: ", enemy.name)


# ----- Handlers (chamados pelos cristais) -----
func handle_purple(player: Node, points: int) -> void:
	# dá pontos ao player
	if player and player.has_method("add_points"):
		player.add_points(points)
		print("[CrystalManager] deu ", points, " pontos ao jogador.")
	# contabiliza e checa se libera vermelhos
	purple_collected += 1
	print("[CrystalManager] purple collected: ", purple_collected, "/", purple_total)
	if purple_total > 0 and purple_collected >= purple_total:
		_unlock_reds()

func handle_yellow() -> void:
	# atordoa o inimigo (duração ajustável)
	var duration := 30.0
	print("[CrystalManager] handle_yellow -> stun enemy ", duration)
	stun_enemy(duration)

func handle_green() -> void:
	# revela o inimigo (duração ajustável)
	var duration := 15.0
	print("[CrystalManager] handle_green -> reveal enemy ", duration)
	reveal_enemy(duration)

func handle_blue(player: Node) -> void:
	# aplica boost de velocidade ao player
	var duration := 10.0
	print("[CrystalManager] handle_blue -> speed boost ", duration)
	if player and player.has_method("apply_speed_boost"):
		player.apply_speed_boost(duration)

func handle_red(player: Node) -> void:
	# exemplo: disparar win_game no player
	if player and player.has_method("win_game"):
		player.win_game()
		print("[CrystalManager] handle_red -> player.win_game() chamado.")


# ----- Ações utilitárias usadas pelos handlers -----
func _unlock_reds() -> void:
	print("[CrystalManager] Liberando cristais vermelhos.")
	for c in red_crystals:
		if is_instance_valid(c):
			c.visible = true

func stun_enemy(duration: float) -> void:
	if enemy_ref and enemy_ref.is_inside_tree() and enemy_ref.has_method("stun"):
		print("[CrystalManager] stun_enemy -> chamando stun() no inimigo")
		enemy_ref.stun(duration)
	else:
		print("[CrystalManager] stun_enemy falhou: enemy_ref inválido ou sem método stun()")

func reveal_enemy(duration: float) -> void:
	if enemy_ref and enemy_ref.is_inside_tree() and enemy_ref.has_method("reveal"):
		print("[CrystalManager] reveal_enemy -> chamando reveal() no inimigo")
		enemy_ref.reveal(duration)
	else:
		print("[CrystalManager] reveal_enemy falhou: enemy_ref inválido ou sem método reveal()")
