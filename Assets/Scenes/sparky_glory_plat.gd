extends CharacterBody3D

# Movimento
const WALK_SPEED = 10.0
const RUN_SPEED = 20.0
const JUMP_FORCE = 9.0
const AIR_CONTROL = 0.3
const GRAVITY = 30.0

# Wall Running
const WALL_RUN_GRAVITY = 8.0
const WALL_JUMP_UP_FORCE = 8.0
const WALL_JUMP_SIDE_FORCE = 15.0
const WALL_MIN_SPEED = 5.0
const WALL_DETECTION_DISTANCE = 0.7

# Dash
const DASH_SPEED = 35.0
const DASH_DURATION = 0.2
const DASH_RECHARGE_TIME = 3.0  # 3 segundos por carga
const MAX_DASH_CHARGES = 4
var dash_charges = MAX_DASH_CHARGES
var dash_time_remaining = 0.0
var dash_direction = Vector3.ZERO
var dash_recharge_timers = []  # Array para controlar cada carga individualmente
var is_recharging_dash = false

# Hook (Whiplash)
const HOOK_SPEED = 40.0
const HOOK_MIN_DISTANCE = 1.5
const HOOK_PULL_FORCE = 25.0
var hook_target = Vector3.ZERO
var is_hooking = false
var whip_length = 0.0
var whip_visible = false
var debug_whiplash = true

# Nodes
@onready var camera = $CameraPivot/Camera3D
@onready var hook_ray = $CameraPivot/Camera3D/RayCast3D
@onready var hook_timer = $HookTimer
@onready var speedometer = $UI/Speedometer
@onready var hook_indicator = $UI/HookIndicator
@onready var dash_charges_display = $UI/DashCharges

# Whiplash Visual Nodes
@onready var whip_anchor = $WhipAnchor
@onready var whip_base = $WhipAnchor/WhipBase
@onready var whip_segment = $WhipAnchor/WhipSegment
@onready var whip_line = $WhipAnchor/WhipLine
@onready var whip_tip = $WhipAnchor/WhipTip
@onready var whip_particles = $WhipAnchor/WhipTip/WhipParticles

# Estados
var current_speed = WALK_SPEED
var is_wall_running = false
var wall_normal = Vector3.ZERO

func _ready():
	hook_ray.target_position = Vector3(0, 0, -50)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	dash_charges_display.text = "DASH: %d" % dash_charges
	
	# Configurar Whiplash visual
	whip_base.visible = false
	whip_segment.visible = false
	whip_line.visible = false
	whip_tip.visible = false
	whip_particles.emitting = false
	
	# Configurar linha dinâmica
	whip_line.mesh = ImmediateMesh.new()
	whip_line.material_override = StandardMaterial3D.new()
	whip_line.material_override.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	whip_line.material_override.albedo_color = Color(0, 0.5, 1)
	whip_line.material_override.emission_enabled = true
	whip_line.material_override.emission = Color(0, 0.3, 0.8)
	
	# Inicializar timers de recarga de dash
	for i in range(MAX_DASH_CHARGES):
		var timer = Timer.new()
		timer.wait_time = DASH_RECHARGE_TIME
		timer.one_shot = true
		timer.name = "DashRechargeTimer_%d" % i
		add_child(timer)
		timer.timeout.connect(_on_dash_recharge_timer_timeout.bind(i))
		dash_recharge_timers.append(timer)

func _physics_process(delta):
	# Aplicar gravidade
	if not is_on_floor() and not is_wall_running:
		velocity.y -= GRAVITY * delta
	
	handle_movement_input(delta)
	handle_special_moves(delta)
	update_ui()
	
	# Aplicar movimento
	move_and_slide()
	
	# Prevenir deslize
	prevent_sliding()
	
	# Atualizar visual do whiplash
	update_whip_visual()

func handle_movement_input(delta):
	# Entrada de movimento
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Sprint
	current_speed = RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	
	# Pulo
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = JUMP_FORCE
	
	# Movimento horizontal
	var air_factor = 1.0 if is_on_floor() else AIR_CONTROL
	
	if dash_time_remaining <= 0:
		if direction:
			velocity.x = direction.x * current_speed * air_factor
			velocity.z = direction.z * current_speed * air_factor
		else:
			var deceleration = current_speed * air_factor * delta * 5.0
			velocity.x = move_toward(velocity.x, 0, deceleration)
			velocity.z = move_toward(velocity.z, 0, deceleration)
	
	# Wall Running
	handle_wall_run(delta)

func handle_wall_run(delta):
	is_wall_running = false
	
	if is_on_floor() or is_hooking or dash_time_remaining > 0:
		return
	
	# Detectar paredes com RayCasts
	var wall_detected = false
	var space_state = get_world_3d().direct_space_state
	
	# RayCast para frente (na direção da câmera)
	var ray_origin = global_position + Vector3.UP * 0.5
	var ray_end = ray_origin + -camera.global_transform.basis.z * WALL_DETECTION_DISTANCE
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [self]
	
	var collision = space_state.intersect_ray(query)
	if collision:
		wall_normal = collision.normal
		if abs(wall_normal.y) < 0.2:
			wall_detected = true
	
	if wall_detected and velocity.length() > WALL_MIN_SPEED:
		is_wall_running = true
		velocity.y = clamp(velocity.y, -1.0, 0.5)
		
		# Wall Jump
		if Input.is_action_just_pressed("jump"):
			var jump_dir = wall_normal * WALL_JUMP_SIDE_FORCE
			jump_dir.y = WALL_JUMP_UP_FORCE
			velocity = jump_dir
			is_wall_running = false

func handle_special_moves(delta):
	# Dash com Ctrl
	if Input.is_action_just_pressed("dash") and dash_charges > 0 and dash_time_remaining <= 0:
		start_dash()
	
	# Atualizar tempo do dash
	if dash_time_remaining > 0:
		dash_time_remaining -= delta
		if dash_time_remaining <= 0:
			end_dash()
	
	# Hook (Whiplash) com R
	if Input.is_action_just_pressed("whiplash"):
		if hook_ray.is_colliding():
			hook_target = hook_ray.get_collision_point()
			is_hooking = true
			hook_timer.start()
			start_whip_effects()
	
	if is_hooking:
		apply_hook_movement()

func start_dash():
	# Direção do dash
	var input_dir = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	var dash_direction_camera = -camera.global_transform.basis.z
	var dash_direction_right = camera.global_transform.basis.x
	
	dash_direction = (dash_direction_camera * input_dir.y + dash_direction_right * input_dir.x).normalized()
	
	if input_dir.length_squared() == 0:
		dash_direction = dash_direction_camera
	
	dash_direction.y = 0
	if dash_direction.length_squared() > 0:
		dash_direction = dash_direction.normalized()
	
	velocity = dash_direction * DASH_SPEED
	dash_time_remaining = DASH_DURATION
	dash_charges -= 1
	dash_charges_display.text = "DASH: %d" % dash_charges
	
	# Iniciar recarga para esta carga
	if dash_charges < MAX_DASH_CHARGES:
		for i in range(dash_charges, MAX_DASH_CHARGES):
			if dash_recharge_timers[i].is_stopped():
				dash_recharge_timers[i].start()
				is_recharging_dash = true
				break

func end_dash():
	velocity = velocity * 0.5

func apply_hook_movement():
	var hook_vector = hook_target - global_position
	var distance = hook_vector.length()
	
	if distance < HOOK_MIN_DISTANCE:
		is_hooking = false
		end_whip_effects()
		return
	
	var hook_direction = hook_vector.normalized()
	var pull_force = min(HOOK_PULL_FORCE, distance * 0.8)
	velocity = velocity.lerp(hook_direction * HOOK_SPEED, 0.2)
	velocity.y = max(velocity.y, -5)

func update_whip_visual():
	if is_hooking:
		if debug_whiplash:
			print("Player Position: ", global_position)
			print("Hook Target: ", hook_target)
			print("Distance: ", global_position.distance_to(hook_target))
		
		var distance = global_position.distance_to(hook_target)
		
		if distance < 0.01:
			if debug_whiplash:
				print("Skipping whip visual update: Distance too small")
			return
		
		whip_length = distance
		
		if distance > 0.1:
			whip_anchor.look_at(hook_target)
		
		whip_segment.mesh.height = distance
		whip_segment.position.z = -distance / 2
		update_whip_line()
		whip_tip.position = Vector3(0, 0, -distance)
		whip_particles.global_position = hook_target
	elif whip_visible:
		retract_whip()

func update_whip_line():
	whip_line.mesh.clear_surfaces()
	whip_line.mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	whip_line.mesh.surface_add_vertex(Vector3.ZERO)
	whip_line.mesh.surface_add_vertex(Vector3(0, 0, -whip_length))
	whip_line.mesh.surface_end()

func start_whip_effects():
	whip_visible = true
	whip_base.visible = true
	whip_segment.visible = true
	whip_line.visible = true
	whip_tip.visible = true
	whip_particles.emitting = true
	
	var tween = create_tween()
	whip_tip.scale = Vector3.ZERO
	tween.tween_property(whip_tip, "scale", Vector3.ONE, 0.1)
	tween.parallel().tween_property(whip_base, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
	tween.tween_property(whip_base, "scale", Vector3.ONE, 0.2)

func end_whip_effects():
	if whip_visible:
		retract_whip()

func retract_whip():
	var tween = create_tween()
	tween.tween_property(whip_segment, "mesh:height", 0.0, 0.2)
	tween.parallel().tween_property(self, "whip_length", 0.0, 0.2)
	tween.parallel().tween_property(whip_tip, "position", Vector3.ZERO, 0.2)
	tween.tween_callback(finish_whip_retraction)

func finish_whip_retraction():
	whip_base.visible = false
	whip_segment.visible = false
	whip_line.visible = false
	whip_tip.visible = false
	whip_particles.emitting = false
	whip_visible = false

func prevent_sliding():
	if is_on_floor() and Vector3(velocity.x, 0, velocity.z).length() < 0.5:
		velocity.x = 0
		velocity.z = 0

func _on_dash_recharge_timer_timeout(timer_index):
	dash_charges += 1
	dash_charges_display.text = "DASH: %d" % dash_charges
	
	# Verificar se ainda há cargas para recarregar
	is_recharging_dash = false
	for i in range(dash_charges, MAX_DASH_CHARGES):
		if not dash_recharge_timers[i].is_stopped():
			is_recharging_dash = true
			break

func _on_hook_timer_timeout():
	is_hooking = false
	end_whip_effects()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * 0.005)
		$CameraPivot.rotate_x(-event.relative.y * 0.005)
		$CameraPivot.rotation.x = clamp($CameraPivot.rotation.x, -PI/2, PI/2)

func update_ui():
	var speed = Vector3(velocity.x, 0, velocity.z).length()
	speedometer.text = "SPEED: %d u/s" % speed
	hook_indicator.visible = hook_ray.is_colliding()
