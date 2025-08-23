extends Node3D

@onready var crow_sound = $corvo
@onready var timer = $corvo/Timer
@onready var player = $Streamer  # Adicione esta linha - ajuste o nome para o seu nó do jogador

func _ready():
	start_timer()
	if player and player.has_method("reset_player"):
		player.reset_player()
	
	# Conecta o sinal se o inimigo existir
	var enemy = get_node_or_null("../Inimigo")
	if enemy and enemy.has_signal("player_died"):
		enemy.player_died.connect(_on_player_died)

func _on_player_died():
	if player and player.has_method("reset_player"):
		player.reset_player()
	print("Jogador morreu - resetando estado")

func start_timer():
	timer.wait_time = randf_range(15, 30.0)
	timer.start()

func _on_timer_timeout():
	crow_sound.play()
	start_timer()
