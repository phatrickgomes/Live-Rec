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
	body_entered.connect(_on_body_entered)
	# Adapta aparência conforme a tipagem
	_aplicar_tipo()

	# Se quiser que os VERMELHOS só apareçam quando todos ROXOS forem coletados:
	# (mantém visível no editor, esconde só em runtime)
	if crystal_type == CrystalType.VERMELHO and not Engine.is_editor_hint():
		visible = false
		# Se você usa um autoload CrystalManager, registre este cristal vermelho:
		# CrystalManager.register_red_crystal(self)

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("Player"):
		return

	match crystal_type:
		CrystalType.ROXO:
			if body.has_method("add_points"):
				body.add_points(points)
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("on_purple_collected"):
				CrystalManager.on_purple_collected()

		CrystalType.AMARELO:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("stun_enemy"):
				CrystalManager.stun_enemy(30.0)

		CrystalType.VERDE:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("reveal_enemy"):
				CrystalManager.reveal_enemy(15.0)

		CrystalType.AZUL:
			if typeof(CrystalManager) != TYPE_NIL and CrystalManager.has_method("speed_boost_player"):
				CrystalManager.speed_boost_player(body, 10.0)

		CrystalType.VERMELHO:
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

	# Cria um material simples em runtime com cor + emissão (brilho)
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
