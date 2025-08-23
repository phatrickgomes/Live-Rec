extends Area3D

# ---- TIPAGEM / EXPORT ----
enum CrystalType { ROXO, AMARELO, VERDE, AZUL, VERMELHO }
@export var crystal_type: CrystalType = CrystalType.ROXO
@export var points: int = 10   # usado para o roxo

# ---- NÓS ----
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var glow: OmniLight3D   = $OmniLight3D

func _ready() -> void:
	# Conecta sinal (Godot 4)
	connect("body_entered", Callable(self, "_on_body_entered"))
	# Ajusta a aparência conforme a tipagem
	_aplicar_tipo()

	# Registro com CrystalManager (se existir) - só em runtime
	if not Engine.is_editor_hint():
		# Vermelho começa oculto em runtime e é registrado para ser liberado depois
		if crystal_type == CrystalType.VERMELHO:
			visible = false
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("register_red_crystal"):
				CrystalManager.register_red_crystal(self)
		# Registra roxos para contabilizar total
		if crystal_type == CrystalType.ROXO:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("register_purple"):
				CrystalManager.register_purple(self)


func _on_body_entered(body: Node) -> void:
	# aceita tanto jogadores no grupo "Player" quanto o player atual registrado (suporta players internos)
	var current_player = null
	if Engine.has_singleton("PlayerManager") and PlayerManager.has_method("get_current_player"):
		current_player = PlayerManager.get_current_player()

	# aceita se for o player atual OU se estiver no grupo "Player"

	# Passa tudo pro manager cuidar (se existir), senão aplica efeito local como fallback
	match crystal_type:
		CrystalType.ROXO:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("handle_purple"):
				CrystalManager.handle_purple(body, points)
			else:
				if body.has_method("add_points"):
					body.add_points(points)

		CrystalType.AMARELO:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("handle_yellow"):
				CrystalManager.handle_yellow()
			else:
				# fallback simples: tenta atordoar enemy_ref se existir
				if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("stun_enemy"):
					CrystalManager.stun_enemy(30.0)

		CrystalType.VERDE:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("handle_green"):
				CrystalManager.handle_green()
			else:
				if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("reveal_enemy"):
					CrystalManager.reveal_enemy(15.0)

		CrystalType.AZUL:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("handle_blue"):
				CrystalManager.handle_blue(body)
			else:
				if body.has_method("apply_speed_boost"):
					body.apply_speed_boost(10.0)

		CrystalType.VERMELHO:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("handle_red"):
				CrystalManager.handle_red(body)
			else:
				if body.has_method("win_game"):
					body.win_game()

	queue_free() # coleta: remove o cristal


# ---------------------------
# Aparência por tipagem
# ---------------------------
func _aplicar_tipo() -> void:
	var col: Color
	match crystal_type:
		CrystalType.ROXO:     col = Color(0.60, 0.20, 0.80)
		CrystalType.AMARELO:  col = Color(1.00, 1.00, 0.30)
		CrystalType.VERDE:    col = Color(0.30, 1.00, 0.30)
		CrystalType.AZUL:     col = Color(0.30, 0.60, 1.00)
		CrystalType.VERMELHO: col = Color(1.00, 0.20, 0.20)

	var mat := _make_glowing_material(col)
	if mesh:
		mesh.material_override = mat
	if glow:
		glow.light_color = col


func _make_glowing_material(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = 1.3
	m.metallic = 0.0
	m.roughness = 0.2
	return m
