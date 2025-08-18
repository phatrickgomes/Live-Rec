extends Node3D

@export var obstacle_scenes: Array[PackedScene]  # Cenas dos obstáculos
@export var spawn_rate = 1.0  # Tempo entre spawns (em segundos)
@export var obstacle_speed = 10.0  # Velocidade dos obstáculos

var timer = 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_rate:
		timer = 0.0
		spawn_obstacle()

func spawn_obstacle():
	var obstacle = obstacle_scenes[randi() % obstacle_scenes.size()].instantiate()
	add_child(obstacle)
	
	# Posiciona o obstáculo longe do jogador e em uma faixa aleatória
	obstacle.position.z = 20  # Distância inicial
	obstacle.position.x = [-lane_width, 0, lane_width][randi() % 3]  # Posição X aleatória
	
	# Configura a velocidade do obstáculo (movendo-se em -Z)
	obstacle.linear_velocity = Vector3(0, 0, -obstacle_speed)
	
	# Adiciona ao grupo para detectar colisão
	obstacle.add_to_group("obstacle")
