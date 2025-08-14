extends CharacterBody3D

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var visao: Area3D = $Visao
@onready var dicas: Area3D = $Dicas
@onready var debug_path: MeshInstance3D = $DebugPath

# Referências para os players de áudio
@onready var audio_dica: AudioStreamPlayer3D = $TrilhaDica
@onready var audio_encontra: AudioStreamPlayer3D = $TrilhaSonora
@onready var audio_investigacao: AudioStreamPlayer3D = $TrilhaInvestigação
@onready var audio_irritado: AudioStreamPlayer3D = $TrilhaIrritado
@onready var audio_enganacao: AudioStreamPlayer3D = $TrilhaEnganação # Novo áudio para o QTE

# Configurações
const SPEED: float = 5.0
const GRAVITY: float = 1.8
const CHASE_DURATION: float = 30.0
const INVESTIGATE_DURATION: float = 15.0
const PATROL_DURATION: float = 10.0
const MIN_DISTANCE: float = 1.0
const ROTATION_SPEED: float = 8.0
const PATH_UPDATE_THRESHOLD: float = 2.0
const DICA_UPDATE_INTERVAL: float = 10.0
const ENRAGED_DURATION: float = 60.0
const TURN_THRESHOLD: float = deg_to_rad(15.0)

# Estados
enum {PATROL, CHASE, INVESTIGATE, ENRAGED, QTE}  # Adicionado QTE
var current_state = PATROL

# Variáveis
var chase_timer: float = 0.0
var investigate_timer: float = 0.0
var patrol_timer: float = PATROL_DURATION
var player: CharacterBody3D = null
var last_known_position: Vector3 = Vector3.ZERO
var patrol_target: Vector3 = Vector3.ZERO
var rng = RandomNumberGenerator.new()
var last_path_update_pos: Vector3 = Vector3.ZERO
var player_in_dicas: bool = false
var is_moving_to_patrol_target: bool = false
var is_investigating_position: bool = false
var dica_update_timer: float = 0.0
var show_path: bool = true

# Novas variáveis para modo enfurecido
var failed_investigate_count: int = 0
var enraged_timer: float = 0.0
var last_direction: Vector3 = Vector3.ZERO
var is_turning: bool = false

# Controle de áudio
var investigacao_sound_played: bool = false

# Variáveis para QTE
var qte_active: bool = false
var qte_success: bool = false
var qte_presses_required: int = 20
var qte_presses_count: int = 0
var qte_time_limit: float = 3.0
var qte_timer: float = 0.0
var qte_last_key: String = ""
var qte_chance: float = 0.6  # 50% de chance inicial
var player_controller: Node = null
var camera_shake_intensity: float = 0.1

func _ready():
	rng.randomize()
	setup_navigation()
	connect_signals()
	set_new_patrol_target()
	
	# Encontra o jogador e sua câmera
	player_controller = get_tree().get_root().get_node("MainScene3D/SparkyGlory")
	
	var immediate_mesh = ImmediateMesh.new()
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	material.vertex_color_use_as_albedo = true
	debug_path.mesh = immediate_mesh
	debug_path.material_override = material

func setup_navigation():
	nav_agent.path_desired_distance = 1.0
	nav_agent.target_desired_distance = 1.0
	nav_agent.avoidance_enabled = true
	nav_agent.path_max_distance = 50.0
	nav_agent.avoidance_layers = 1

func connect_signals():
	visao.body_entered.connect(_on_Visao_body_entered)
	visao.body_exited.connect(_on_Visao_body_exited)
	dicas.body_entered.connect(_on_Dicas_body_entered)
	dicas.body_exited.connect(_on_Dicas_body_exited)

func _physics_process(delta):
	if qte_active:
		handle_qte(delta)
		return
	
	apply_gravity(delta)
	update_timers(delta)
	handle_movement(delta)
	
	if player_in_dicas and current_state != CHASE and current_state != ENRAGED:
		dica_update_timer = max(0.0, dica_update_timer - delta)
		if dica_update_timer <= 0.0:
			update_dica_position()
			dica_update_timer = DICA_UPDATE_INTERVAL
	
	move_and_slide()
	draw_debug_path()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

func update_timers(delta):
	match current_state:
		CHASE:
			if player and is_player_visible():
				chase_timer = CHASE_DURATION
			else:
				chase_timer = max(0.0, chase_timer - delta)
				if chase_timer <= 0.0:
					enter_patrol_state()
		
		INVESTIGATE:
			investigate_timer = max(0.0, investigate_timer - delta)
			
			# Toca som de investigação quando chega ao destino
			if nav_agent.is_navigation_finished() and not investigacao_sound_played:
				play_investigacao_sound()
				investigacao_sound_played = true
				
				# Chance de iniciar QTE
				if rng.randf() < qte_chance:
					start_qte()
			
			if nav_agent.is_navigation_finished() or investigate_timer <= 0.0:
				enter_patrol_state()
		
		PATROL:
			if not is_moving_to_patrol_target:
				patrol_timer = max(0.0, patrol_timer - delta)
				if patrol_timer <= 0.0:
					set_new_patrol_target()
		
		ENRAGED:
			enraged_timer = max(0.0, enraged_timer - delta)
			if enraged_timer <= 0.0:
				current_state = PATROL
				print("Saindo do modo enfurecido")
				# Resetar contagem após enfurecido
				failed_investigate_count = 0

func handle_movement(delta: float):
	var target_pos = get_current_target()
	
	# Atualização especial para estado enfurecido
	if current_state == ENRAGED and player:
		nav_agent.target_position = player.global_position
		last_path_update_pos = global_position
		target_pos = player.global_position
	else:
		if should_update_target(target_pos):
			nav_agent.target_position = target_pos
			last_path_update_pos = global_position
			is_moving_to_patrol_target = (current_state == PATROL)
	
	if nav_agent.is_navigation_finished():
		if current_state == PATROL:
			is_moving_to_patrol_target = false
			velocity.x = 0
			velocity.z = 0
		elif current_state == INVESTIGATE:
			is_investigating_position = true
			velocity.x = 0
			velocity.z = 0
		return
	
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position)
	var distance = direction.length()
	
	if distance > MIN_DISTANCE:
		direction = direction.normalized()
		
		# Cálculo de velocidade modificado para modo enfurecido
		var current_speed = SPEED
		var current_rotation_speed = ROTATION_SPEED
		
		if current_state == ENRAGED:
			current_speed = SPEED * 2  # Velocidade dobrada
			
			# Detecção de curva
			if last_direction != Vector3.ZERO:
				var angle = last_direction.angle_to(direction)
				is_turning = angle > TURN_THRESHOLD
				
				if is_turning:
					current_speed = SPEED  # Volta à velocidade normal em curvas
					current_rotation_speed = ROTATION_SPEED * 1.5  # Gira mais rápido
		
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if distance > 1.0:
			var horizontal_direction = Vector2(direction.x, direction.z).normalized()
			rotation.y = lerp_angle(rotation.y, atan2(horizontal_direction.x, horizontal_direction.y), current_rotation_speed * delta)
		
		# Guarda direção atual para próximo frame
		last_direction = direction
	else:
		velocity.x = 0
		velocity.z = 0
		last_direction = Vector3.ZERO

func should_update_target(target_pos: Vector3) -> bool:
	return nav_agent.target_position.distance_to(target_pos) > PATH_UPDATE_THRESHOLD || \
		   global_position.distance_to(last_path_update_pos) > PATH_UPDATE_THRESHOLD

func get_current_target() -> Vector3:
	match current_state:
		CHASE: 
			if player:
				return player.global_position
			else:
				return last_known_position
		INVESTIGATE: 
			return last_known_position
		PATROL: 
			return patrol_target
		ENRAGED:  # Sempre sabe onde o jogador está
			if player:
				return player.global_position
			else:
				return last_known_position
		_:
			return patrol_target

func set_new_patrol_target():
	var random_angle = rng.randf_range(0, TAU)
	var random_radius = rng.randf_range(15.0, 25.0)
	patrol_target = global_position + Vector3(cos(random_angle), 0, sin(random_angle)) * random_radius
	patrol_timer = PATROL_DURATION
	
	print("Novo destino de patrulha: ", patrol_target)
	nav_agent.target_position = patrol_target
	last_path_update_pos = global_position
	is_moving_to_patrol_target = true

func enter_patrol_state():
	# Contabiliza investigação fracassada
	if current_state == INVESTIGATE:
		failed_investigate_count += 1
		print("Investigações fracassadas: ", failed_investigate_count)
		
		# Aumenta chance de QTE para próxima investigação
		qte_chance = min(qte_chance + 0.1, 1.0)  # Aumenta 10%, máximo 100%
		print("Nova chance de QTE: ", qte_chance * 100, "%")
		
		# Ativa modo enfurecido após 3 falhas
		if failed_investigate_count >= 3:
			enter_enraged_state()
			return
	
	current_state = PATROL
	set_new_patrol_target()
	is_investigating_position = false
	investigacao_sound_played = false
	print("Voltando à patrulha")

func enter_enraged_state():
	print("ENTRANDO EM MODO ENFURECIDO!")
	current_state = ENRAGED
	enraged_timer = ENRAGED_DURATION
	
	# Resetar direção anterior
	last_direction = Vector3.ZERO
	
	# Garantir que sabe onde o jogador está
	if player:
		last_known_position = player.global_position
		nav_agent.target_position = last_known_position
		last_path_update_pos = global_position
	
	# Toca som de enfurecido
	play_irritado_sound()

func is_player_visible() -> bool:
	return player != null and player in visao.get_overlapping_bodies()

func get_state_name() -> String:
	match current_state:
		PATROL: return "PATROL"
		CHASE: return "CHASE"
		INVESTIGATE: return "INVESTIGATE"
		ENRAGED: return "ENRAGED"
		QTE: return "QTE"
		_: return "UNKNOWN"

func draw_debug_path():
	if not show_path:
		return
	
	var immediate_mesh = debug_path.mesh as ImmediateMesh
	immediate_mesh.clear_surfaces()
	
	var path = nav_agent.get_current_navigation_path()
	if path.size() > 1:
		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(path.size()):
			var color = Color.RED
			match current_state:
				PATROL: color = Color.GREEN
				CHASE: color = Color.RED
				INVESTIGATE: color = Color.YELLOW
				ENRAGED: color = Color.PURPLE
				QTE: color = Color.ORANGE
			
			immediate_mesh.surface_set_color(color)
			immediate_mesh.surface_add_vertex(to_local(path[i]))
		immediate_mesh.surface_end()

func toggle_path_visibility():
	show_path = !show_path
	print("Visualização do caminho: ", "ATIVADA" if show_path else "DESATIVADA")
	
	if not show_path:
		var immediate_mesh = debug_path.mesh as ImmediateMesh
		immediate_mesh.clear_surfaces()

func update_dica_position():
	if player and player_in_dicas:
		print("Atualizando posição pela dica periódica")
		last_known_position = player.global_position
		
		if current_state != CHASE:
			current_state = INVESTIGATE
			investigate_timer = INVESTIGATE_DURATION
			nav_agent.target_position = last_known_position
			last_path_update_pos = global_position
			is_investigating_position = true
			$DicasFeedback.restart()
			# Toca som de dica
			play_dica_sound()

# Funções para tocar sons
func play_dica_sound():
	if not audio_dica.playing:
		audio_dica.play()
		print("Tocando TrilhaDica")

func play_encontra_sound():
	if not audio_encontra.playing:
		audio_encontra.play()
		print("Tocando TrilhaSonora (encontrou jogador)")

func play_investigacao_sound():
	if not audio_investigacao.playing:
		audio_investigacao.play()
		print("Tocando TrilhaInvestigação")

func play_irritado_sound():
	if not audio_irritado.playing:
		audio_irritado.play()
		print("Tocando TrilhaIrritado (modo enfurecido)")

# ===== NOVAS FUNÇÕES PARA QTE =====
func start_qte():
	if player_controller == null:
		return
	
	print("Iniciando Quick Time Event!")
	qte_active = true
	qte_success = false
	qte_presses_count = 0
	qte_timer = qte_time_limit
	qte_last_key = ""
	
	# Toca som de enganação
	audio_enganacao.play()
	
	# Força o jogador a olhar para o inimigo
	if player:
		player_controller.look_at(global_position)
	
	# Mostra UI de QTE (se implementado)
	# player_controller.show_qte_ui()

func end_qte():
	qte_active = false
	investigacao_sound_played = false
	
	if qte_success:
		print("QTE bem sucedido! Inimigo enganado.")
		# Não conta como investigação falhada
		failed_investigate_count = max(0, failed_investigate_count - 1)
	else:
		print("QTE falhou!")
		# Conta como falha
		failed_investigate_count += 1
	
	# Esconde UI de QTE (se implementado)
	# player_controller.hide_qte_ui()
	if player:
		player.end_qte()
	# Volta ao estado normal
	enter_patrol_state()

func handle_qte(delta):
	# Atualiza temporizador
	qte_timer = max(0.0, qte_timer - delta)
	
	# Movimenta jogador em direção ao inimigo
	if player:
		var direction = (global_position - player.global_position).normalized()
		player.velocity = direction * SPEED * 0.5
		player.move_and_slide()
	
	# Aplica tremor na câmera
	if player_controller and player_controller.camera:
		var camera = player_controller.camera
		var shake_offset = Vector3(
			randf_range(-camera_shake_intensity, camera_shake_intensity),
			randf_range(-camera_shake_intensity, camera_shake_intensity),
			randf_range(-camera_shake_intensity, camera_shake_intensity)
		)
		camera.position = camera.position.lerp(shake_offset, 0.5)
	
	# Verifica se o tempo acabou
	if qte_timer <= 0.0:
		end_qte()

func _input(event):
	if !qte_active:
		return
	
	# Verifica apenas eventos de tecla pressionada
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_A or event.keycode == KEY_D:
			# Alterna entre A e D
			var current_key = "A" if event.keycode == KEY_A else "D"
			
			if qte_last_key == "" or qte_last_key != current_key:
				qte_presses_count += 1
				qte_last_key = current_key
				
				# Atualiza UI (se implementado)
				# player_controller.update_qte_ui(qte_presses_count, qte_presses_required)
				
				print("QTE: ", qte_presses_count, "/", qte_presses_required)
				
				# Verifica se completou
				if qte_presses_count >= qte_presses_required:
					qte_success = true
					end_qte()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			toggle_path_visibility()

func _on_navigation_finished():
	print("Chegou ao destino: ", nav_agent.target_position)
	if current_state == PATROL:
		is_moving_to_patrol_target = false

func _on_Visao_body_entered(body: Node3D):
	if body.name == "SparkyGlory" and body is CharacterBody3D:
		print("Jogador detectado na visão! Perseguindo...")
		player = body
		last_known_position = body.global_position
		current_state = CHASE
		chase_timer = CHASE_DURATION
		nav_agent.target_position = last_known_position
		last_path_update_pos = global_position
		is_investigating_position = false
		# Resetar contagem ao ver jogador
		failed_investigate_count = 0
		# Resetar chance de QTE
		qte_chance = 0.9
		# Toca som de encontro com jogador
		play_encontra_sound()

func _on_Visao_body_exited(body: Node3D):
	if body.name == "SparkyGlory" and body is CharacterBody3D:
		print("Jogador saiu da visão")

func _on_Dicas_body_entered(body: Node3D):
	if body.name == "SparkyGlory" and body is CharacterBody3D:
		print("Jogador entrou na área de dicas")
		player_in_dicas = true
		player = body
		update_dica_position()
		dica_update_timer = DICA_UPDATE_INTERVAL

func _on_Dicas_body_exited(body: Node3D):
	if body.name == "SparkyGlory" and body is CharacterBody3D:
		print("Jogador saiu da área de dicas")
		player_in_dicas = false
