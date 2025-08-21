# Orb.gd (Godot 4.4.1) — único script para Azul/Verde/Amarelo
extends Area3D

@export_enum("Azul", "Verde", "Amarelo") var orb_type: String = "Azul"

# PUXÃO (Azul/Verde)
@export var pull_target_speed: float = 22.0     # velocidade alvo do puxão (u/s)
@export var pull_lerp: float = 0.18             # suavização pra chegar na velocidade alvo (0..1)
@export var stop_distance: float = 1.2          # quando a distância for <= isso, considera “chegou”

# IMPULSO (Azul)
@export var impulse_boost: float = 28.0         # “chute” extra ao atingir o orbe

# TELEPORTE (Amarelo)
@export var teleport_down_offset: float = 1.0   # teleporta pra BAIXO do orbe (Y-)

# FX (flash rápido)
@export var fx_size: float = 0.5
@export var fx_energy: float = 2.0
@export var fx_duration: float = 0.25

var player: CharacterBody3D = null
var active: bool = false
var last_dir: Vector3 = Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	if not active or player == null:
		return

	var orb_pos := global_position
	var ppos := player.global_position
	var vec := orb_pos - ppos
	var dist := vec.length()
	if dist <= 0.0001:
		return
	var dir := vec / dist
	last_dir = dir

	match orb_type:
		"Azul":
			if dist > stop_distance:
				# puxa SUAVEMENTE: ajusta velocity do player rumo a uma velocidade-alvo
				var target_vel := dir * pull_target_speed
				player.velocity = player.velocity.lerp(target_vel, pull_lerp)
			else:
				# chegou -> dá impulso na direção do puxão UMA vez e solta
				player.velocity += dir * impulse_boost
				_spawn_flash_fx(Color(0.2, 0.6, 1.0)) # azul
				_deactivate()
		"Verde":
			if dist > stop_distance:
				var target_vel2 := dir * pull_target_speed
				player.velocity = player.velocity.lerp(target_vel2, pull_lerp)
			else:
				# chegou -> para e solta (não fica aplicando força depois)
				player.velocity = Vector3.ZERO
				_spawn_flash_fx(Color(0.2, 1.0, 0.4)) # verde
				_deactivate()
		_:
			# Amarelo não usa _physics_process (teleporta no enter)
			active = false

func _on_body_entered(body: Node) -> void:
	# Garanta que seu Player está no grupo "player"
	if not body.is_in_group("Sparky"):
		return

	player = body as CharacterBody3D
	if player == null:
		return

	match orb_type:
		"Azul", "Verde":
			active = true
		"Amarelo":
			# Teleporta exatamente para BAIXO do orbe (evita “pra frente”)
			var tgt := global_position - Vector3(0, teleport_down_offset, 0)
			player.global_position = tgt
			player.velocity = Vector3.ZERO
			_spawn_flash_fx(Color(1.0, 0.9, 0.3)) # amarelo
			_deactivate()

func _on_body_exited(body: Node) -> void:
	if body == player:
		# Se sair da área antes de completar, apenas solta sem dar efeitos errados
		_deactivate()

func _deactivate() -> void:
	active = false
	player = null
	last_dir = Vector3.ZERO

# ---------- FX simples (esfera + luz que cresce e desaparece) ----------
func _spawn_flash_fx(col: Color) -> void:
	if not is_inside_tree():
		return

	# Adiciona como filho do Orbe (mais seguro)
	var fx_root := self

	# Esfera emissiva
	var mesh := MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.scale = Vector3(fx_size, fx_size, fx_size)

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = fx_energy
	mat.albedo_color = col
	mesh.material_override = mat
	mesh.global_position = global_position
	fx_root.add_child(mesh)

	# Luz rápida
	var light := OmniLight3D.new()
	light.light_color = col
	light.light_energy = fx_energy
	light.range = 6.0
	light.global_position = global_position
	fx_root.add_child(light)

	# Tween de “boom”
	var tw := get_tree().create_tween()
	tw.tween_property(mesh, "scale", mesh.scale * 2.0, fx_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(light, "light_energy", 0.0, fx_duration)
	tw.tween_callback(func ():
		mesh.queue_free()
		light.queue_free())
