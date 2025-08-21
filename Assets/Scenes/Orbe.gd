extends Area3D

# Configuração do Orbe
@export_enum("Azul", "Verde", "Amarelo") var orb_type: String = "Amarelo"
@export var pull_strength: float = 15.0
@export var stop_distance: float = 1.0 # Distância mínima para parar o jogador
@export var teleport_offset: Vector3 = Vector3(0, 1, 0) # Evita teleportar dentro do chão

# Jogador que vai ser puxado
var player: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	match orb_type:
		"Azul":
			_pull_player_with_impulse(delta)
		"Verde":
			_pull_player_and_stop(delta)
		"Amarelo":
			_teleport_player()
			player = null # depois do teleporte, reseta

# ========================
#       MECÂNICAS
# ========================

func _pull_player_with_impulse(delta: float) -> void:
	var dir: Vector3 = (global_transform.origin - player.global_transform.origin).normalized()
	var body := player as CharacterBody3D
	if body:
		body.velocity += dir * pull_strength * delta

func _pull_player_and_stop(delta: float) -> void:
	var dir: Vector3 = global_transform.origin - player.global_transform.origin
	var distance := dir.length()
	if distance > stop_distance:
		var body := player as CharacterBody3D
		if body:
			body.velocity += dir.normalized() * pull_strength * delta
	else:
		var body := player as CharacterBody3D
		if body:
			body.velocity = Vector3.ZERO

func _teleport_player() -> void:
	if player:
		player.global_transform.origin = global_transform.origin + teleport_offset

# ========================
#       SINAIS
# ========================

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Sparky"): # adicione o jogador no grupo "player"
		player = body

func _on_body_exited(body: Node) -> void:
	if body == player:
		player = null
