extends Node

@export var obstacle_scenes: Array[PackedScene]
@export var spawn_rate = 1.0  # Segundos entre obstáculos

var timer = 0.0

func _process(delta):
	timer += delta
	if timer >= spawn_rate:
		timer = 0
		spawn_obstacle()

func spawn_obstacle():
	var obstacle = obstacle_scenes[randi() % obstacle_scenes.size()].instantiate()
	add_child(obstacle)
	obstacle.position.z = 50  # Começa longe do jogador
	obstacle.position.x = [-4, 0, 4][randi() % 3]  # Posição aleatória em uma das faixas
