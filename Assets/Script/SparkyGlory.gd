extends CharacterBody3D

### Configurações de movimento ###
@export var mouse_sensitivity: float = 0.002
@export var vertical_angle_limit: float = 90.0
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 8.0
@export var acceleration: float = 10.0
@export var jump_force: float = 4.5
@export var diagonal_speed_multiplier: float = 1.4

### Efeitos de câmera ###
var t_bob: float = 0.0
var bob_freq: float = 2.0
var bob_amp: float = 0.07

### Componentes ###
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D
@onready var passo = $passo
@onready var qte_ui = $QTE_UI
@onready var qte_a_label = $QTE_UI/CenterContainer/VBoxContainer/HBoxContainer/A/Label
@onready var qte_d_label = $QTE_UI/CenterContainer/VBoxContainer/HBoxContainer/D/Label

# Lanterna
@onready var lanterna: SpotLight3D = get_node_or_null("CameraPivot/Camera3D/Lanterna")
var lanterna_ativa: bool = true
var bateria: float = 100.0 # %
var drenagem: float = 10.0 # % por minuto

# Falha da lanterna
var tempo_falha: float = 0.0
var intervalo_falha: float = 10.0 # a cada 10s
var chance_falha: float = 0.90
var falhou: bool = false
var tentativas_religar: int = 0
var tentativas_necessarias: int = 5

### Variáveis de estado ###
var current_speed: float = walk_speed
var vertical_rotation: float = 0.0
var camera_original_position: Vector3
var camera_original_rotation: Vector3

### Variáveis QTE ###
var qte_active: bool = false
var qte_target_position: Vector3 = Vector3.ZERO
var qte_shake_timer: float = 0.0
var qte_shake_intensity: float = 0.3
var qte_rotation_shake_intensity: float = 0.8
var qte_mouse_shake_intensity: float = 250.0
var original_mouse_sensitivity: float
var qte_current_key: String = "A"
var qte_presses_required: int = 20
var qte_current_presses: int = 0
var qte_enemy_ref: Node = null
var points: int = 0
var speed_boost_timer: float = 0.0
var boosted: bool = false

func add_points(amount: int):
	points += amount
	print("Pontos: ", points)

func apply_speed_boost(duration: float):
	boosted = true
	speed_boost_timer = duration
	walk_speed *= 2
	sprint_speed *= 2

func _unhandled_input(event):
	if event.is_action_pressed("lanterna_toggle"):
		if falhou:
			# Jogador tentando religar após falha
			tentativas_religar += 1
			if tentativas_religar >= tentativas_necessarias:
				religar_lanterna()
		else:
			if bateria > 0:
				lanterna_ativa = !lanterna_ativa
				lanterna.visible = lanterna_ativa

func _ready():
	PlayerManager.register_internal_player(self)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_original_position = camera.position
	camera_original_rotation = camera.rotation
	original_mouse_sensitivity = mouse_sensitivity

	# Garante que temos as ações mesmo dentro do SubViewport
	_ensure_input_actions()

	# Estado inicial da lanterna
	if lanterna:
		lanterna.visible = lanterna_ativa
		lanterna.light_energy = 2.0 # brilho padrão

	# UI QTE
	if qte_ui:
		qte_ui.visible = false
		update_qte_ui()
	else:
		printerr("ERRO: QTE_UI não encontrada como filho do Player.")

func _ensure_input_actions():
	if not InputMap.has_action("lanterna_toggle"):
		InputMap.add_action("lanterna_toggle")
		var ev := InputEventKey.new()
		ev.keycode = KEY_F
		InputMap.action_add_event("lanterna_toggle", ev)

func _process(delta):
	# Consumo de bateria
	if lanterna_ativa and bateria > 0 and not falhou:
		bateria -= drenagem * delta / 60.0
		if bateria <= 0:
			bateria = 0
			desligar_lanterna()

	# Sistema de falha
	if not falhou and lanterna_ativa:
		tempo_falha += delta
		if tempo_falha >= intervalo_falha:
			tempo_falha = 0
			if randf() <= chance_falha:
				falha_lanterna()
	if boosted:
		speed_boost_timer -= delta
		if speed_boost_timer <= 0:
			boosted = false
			walk_speed /= 2
			sprint_speed /= 2
func desligar_lanterna():
	lanterna_ativa = false
	if lanterna:
		lanterna.visible = false

func falha_lanterna():
	falhou = true
	lanterna_ativa = false
	if lanterna:
		lanterna.visible = false
		lanterna.light_energy = 0.5
	tentativas_religar = 0
	_start_flicker_effect()

func religar_lanterna():
	falhou = false
	lanterna_ativa = true
	if lanterna:
		lanterna.visible = true
		lanterna.light_energy = 2.0
	tentativas_religar = 0

func _start_flicker_effect():
	if not lanterna:
		return
	var flicker_times = 4
	for i in range(flicker_times):
		lanterna.visible = not lanterna.visible
		await get_tree().create_timer(0.15).timeout
	lanterna.visible = false

func _input(event):
	if qte_active:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_A:
				on_qte_key_pressed("A")
			elif event.keycode == KEY_D:
				on_qte_key_pressed("D")
		return

	# Olhar com o mouse
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		vertical_rotation = clamp(
			vertical_rotation - event.relative.y * mouse_sensitivity,
			deg_to_rad(-vertical_angle_limit),
			deg_to_rad(vertical_angle_limit)
		)
		camera_pivot.rotation.x = vertical_rotation

	# ESC / recapturar mouse
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventMouseButton and event.pressed and Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if Global.Ta_no_jogo:
		if qte_active:
			handle_qte_movement(delta)
			apply_camera_shake(delta)
			apply_mouse_shake()
			apply_qte_effects(delta)
			return

		handle_movement(delta)
		current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed

		if is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = jump_force

		if not is_on_floor():
			velocity.y -= 9.8 * delta

		move_and_slide()

		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = _headbob(t_bob) + Vector3(0, 0.5, 0)

func _set_lanterna(active: bool):
	lanterna_ativa = active
	if lanterna:
		lanterna.visible = active


func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))

	if input_dir.length() > 0:
		if abs(input_dir.x) > 0.1 and abs(input_dir.y) > 0.1:
			direction = direction.normalized() * diagonal_speed_multiplier

	var target_velocity = direction * current_speed
	velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)

	if is_on_floor() and input_dir.length() > 0 and !passo.playing and !qte_active:
		if Input.is_action_pressed("sprint"):
			passo.pitch_scale = randf_range(1.2, 1.3)
		else:
			passo.pitch_scale = randf_range(0.9, 1.1)
		passo.play()

func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

### Sistema QTE ###
func start_qte(enemy_position: Vector3, enemy_ref: Node):
	if not qte_ui:
		printerr("QTE_UI não disponível!")
		return

	qte_active = true
	qte_target_position = enemy_position
	qte_enemy_ref = enemy_ref
	qte_shake_timer = 0.0

	qte_ui.visible = true
	qte_ui.raise()

	qte_current_key = "A"
	update_qte_ui()

	var direction = (qte_target_position - global_position).normalized()
	direction.y = 0
	rotation.y = atan2(direction.x, direction.z)

	vertical_rotation = 0
	camera_pivot.rotation.x = 0
	camera.rotation = camera_original_rotation

	mouse_sensitivity = original_mouse_sensitivity * 2.0

func end_qte():
	qte_active = false
	if qte_ui:
		qte_ui.visible = false

	camera.position = camera_original_position
	camera.rotation = camera_original_rotation
	camera_pivot.rotation = Vector3.ZERO
	mouse_sensitivity = original_mouse_sensitivity

func handle_qte_movement(delta):
	var direction = (qte_target_position - global_position).normalized()
	direction.y = 0
	velocity = direction * (walk_speed * 0.5)
	move_and_slide()

	var body_shake = randf_range(-qte_rotation_shake_intensity, qte_rotation_shake_intensity)
	rotation.y += body_shake
	camera_pivot.rotation.x = randf_range(-0.1, 0.1)

func apply_camera_shake(delta):
	qte_shake_timer += delta * 140.0
	var shake_offset = Vector3(
		(sin(qte_shake_timer * 1.7) + cos(qte_shake_timer * 2.3)) * qte_shake_intensity,
		(sin(qte_shake_timer * 1.3) + cos(qte_shake_timer * 2.7)) * qte_shake_intensity,
		(sin(qte_shake_timer * 1.5) + cos(qte_shake_timer * 2.1)) * qte_shake_intensity
	)
	camera.position = camera_original_position + shake_offset
	camera.rotation = camera_original_rotation + Vector3(
		shake_offset.z * 0.8,
		shake_offset.x * 0.8,
		shake_offset.y * 0.8
	)

func apply_mouse_shake():
	var fake_mouse_motion = InputEventMouseMotion.new()
	fake_mouse_motion.relative = Vector2(
		randf_range(-qte_mouse_shake_intensity, qte_mouse_shake_intensity),
		randf_range(-qte_mouse_shake_intensity, qte_mouse_shake_intensity)
	)
	get_viewport().push_input(fake_mouse_motion)

func apply_qte_effects(delta):
	var shake_offset = Vector3(
		randf_range(-qte_shake_intensity, qte_shake_intensity),
		randf_range(-qte_shake_intensity, qte_shake_intensity),
		0
	)
	camera.position += shake_offset

func on_qte_key_pressed(key: String):
	if !qte_active or !qte_ui:
		return

	if key == "A" and qte_a_label:
		qte_a_label.add_theme_color_override("font_color", Color.GREEN)
		var tween = create_tween()
		tween.tween_property(qte_a_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(qte_a_label, "scale", Vector2(1, 1), 0.1)
		tween.tween_callback(func():
			if qte_current_key == "A":
				qte_a_label.add_theme_color_override("font_color", Color.YELLOW)
			else:
				qte_a_label.add_theme_color_override("font_color", Color.WHITE)
		)
	elif key == "D" and qte_d_label:
		qte_d_label.add_theme_color_override("font_color", Color.GREEN)
		var tween2 = create_tween()
		tween2.tween_property(qte_d_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween2.tween_property(qte_d_label, "scale", Vector2(1, 1), 0.1)
		tween2.tween_callback(func():
			if qte_current_key == "D":
				qte_d_label.add_theme_color_override("font_color", Color.YELLOW)
			else:
				qte_d_label.add_theme_color_override("font_color", Color.WHITE)
		)

	if qte_enemy_ref and qte_enemy_ref.has_method("qte_input"):
		qte_enemy_ref.qte_input(key)

func update_qte_key(next_key: String):
	qte_current_key = next_key
	update_qte_ui()

func update_qte_ui():
	if not qte_ui or not qte_a_label or not qte_d_label:
		return

	if qte_current_key == "A":
		qte_a_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		qte_d_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	else:
		qte_a_label.add_theme_color_override("font_color", Color(1, 1, 0, 1))
		qte_d_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func is_in_qte() -> bool:
	return qte_active
