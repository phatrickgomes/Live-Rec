extends CharacterBody3D

# Configurações
var lateral_speed = 10.0  # Velocidade de movimento lateral
var lane_width = 2.0      # Distância entre faixas
var target_x = 0.0        # Posição X alvo
var current_lane = 1      # 0 = esquerda, 1 = centro, 2 = direita
var lanes = [-lane_width, 0.0, lane_width]  # Posições X das faixas

func _ready():
	target_x = lanes[current_lane]  # Começa no centro

func _physics_process(delta):
	# Movimento lateral com A/D
	if Input.is_action_just_pressed("ui_left") and current_lane > 0:
		current_lane -= 1
		target_x = lanes[current_lane]
	elif Input.is_action_just_pressed("ui_right") and current_lane < 2:
		current_lane += 1
		target_x = lanes[current_lane]
	
	# Suaviza o movimento entre faixas
	position.x = lerp(position.x, target_x, delta * lateral_speed)
	
	# Mantém o jogador parado no eixo Z (obstáculos vêm até ele)
	velocity.z = 0  
	move_and_slide()

# Detecta colisão com obstáculos
func _on_body_entered(body):
	if body.is_in_group("obstacle"):
		print("Game Over! Bateu no obstáculo!")
		# Recarrega a cena ou exibe tela de game over
		get_tree().reload_current_scene()
