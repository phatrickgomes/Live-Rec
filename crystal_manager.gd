extends Node

var purple_total: int = 0
var purple_collected: int = 0
var enemy_ref: Node = null
var red_crystals: Array[Node] = []

func register_enemy(enemy):
	enemy_ref = enemy

func register_red_crystal(c):
	c.visible = false
	red_crystals.append(c)

func on_purple_collected():
	purple_collected += 1
	if purple_collected >= purple_total:
		# libera cristais vermelhos
		for c in red_crystals:
			c.visible = true

func stun_enemy(duration: float):
	if enemy_ref:
		enemy_ref.stun(duration)

func reveal_enemy(duration: float):
	if enemy_ref:
		enemy_ref.reveal(duration)

func speed_boost_player(player, duration: float):
	player.apply_speed_boost(duration)
