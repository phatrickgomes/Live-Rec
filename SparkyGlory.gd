extends CharacterBody3D

# Configurações de sensibilidade
@export var mouse_sensitivity: float = 0.002
@export var vertical_angle_limit: float = 90.0


# Configurações de movimento
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 8.0
@export var acceleration: float = 10.0
@export var jump_force: float = 4.5
@export var diagonal_speed_multiplier: float = 1.4

# Configurações do headbob
var t_bob: float = 0.0
var bob_freq: float = 2.0
var bob_amp: float = 0.07

# Componentes da cena
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

# Variáveis de controle
var current_speed: float = walk_speed
var vertical_rotation: float = 0.0
var camera_original_position: Vector3 = Vector3.ZERO
var camera_original_rotation: Vector3 = Vector3.ZERO

# Variáveis para QTE
var qte_active: bool = false
var qte_target_position: Vector3 = Vector3.ZERO
var qte_shake_timer: float = 0.0
var qte_shake_intensity: float = 0.3
var qte_rotation_shake_intensity: float = 0.8
var qte_mouse_shake_intensity: float = 250.0
var original_mouse_sensitivity: float = 0.002

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_original_position = camera.position
	camera_original_rotation = camera.rotation
	original_mouse_sensitivity = mouse_sensitivity
	
func _input(event):
	if qte_active:
		return
		
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		vertical_rotation = clamp(
			vertical_rotation - event.relative.y * mouse_sensitivity,
			deg_to_rad(-vertical_angle_limit),
			deg_to_rad(vertical_angle_limit)
		)
		camera_pivot.rotation.x = vertical_rotation
		
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			
	if event is InputEventMouseButton and event.pressed:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if qte_active:
		handle_qte_movement(delta)
		apply_camera_shake(delta)
		apply_mouse_shake()
		return
	
	handle_movement(delta)
	current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	
	move_and_slide()
	
	# Headbob só quando no chão e se movendo
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob) + Vector3(0, 0.5, 0)
	


func handle_movement(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y))
	
	if input_dir.length() > 0:
		if abs(input_dir.x) > 0.1 and abs(input_dir.y) > 0.1:
			direction = direction.normalized() * diagonal_speed_multiplier
	
	var target_velocity = direction * current_speed
	velocity.x = lerp(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, acceleration * delta)

# ===== Headbob =====
func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

# ===== FUNÇÕES PARA QTE =====
func start_qte(enemy_position: Vector3):
	print("Jogador iniciando QTE")
	qte_active = true
	qte_target_position = enemy_position
	qte_shake_timer = 0.0
	look_at(qte_target_position, Vector3.UP)
	vertical_rotation = 0
	camera_pivot.rotation.x = 0
	mouse_sensitivity = original_mouse_sensitivity * 2.0

func end_qte():
	print("Jogador terminando QTE")
	qte_active = false
	camera.position = camera_original_position
	camera.rotation = camera_original_rotation
	camera_pivot.rotation = Vector3.ZERO
	mouse_sensitivity = original_mouse_sensitivity

func handle_qte_movement(delta):
	var direction = (qte_target_position - global_position).normalized()
	direction.y = 0
	velocity = direction * (walk_speed * 0.5)
	move_and_slide()
	
	var current_rotation = global_transform.basis.get_euler().y
	var target_rotation = (qte_target_position - global_position).normalized()
	target_rotation = atan2(target_rotation.x, target_rotation.z)
	
	var body_shake = randf_range(-qte_rotation_shake_intensity, qte_rotation_shake_intensity)
	rotation.y = target_rotation + body_shake
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

func is_in_qte() -> bool:
	return qte_active
