extends CharacterBody3D

signal interact_object

##nos e referencias
@onready var camera_pivot: Node3D = $camera_pivot
@onready var camera: Camera3D = $camera_pivot/Camera3D
@onready var camera_monitor: Camera3D = get_node_or_null("../GUI/Monitor")
@onready var raycast = $camera_pivot/Camera3D/interacao
@onready var mao = $camera_pivot/Camera3D/CarryObjectMaker
@onready var interacao_gui = $"../GUI"
@onready var interact_label: Label = $CanvasLayer/interact_label
@onready var ponto_da_camera = $Label
@onready var labrinto: Node3D = $".."

##variaveis principais
var objeto_selecionado = null
const SPEED = 4.0
const SENSIBILIDADE = 0.003
var mouse = Vector2()
var interagindo_com_tela = false
var em_transicao = false
var tween_atual: Tween = null
var camera_inicial_transform: Transform3D

 ##variaveis para headbob
var t_bob: float = 0.0
var bob_freq: float = 2.0
var bob_amp: float = 0.07

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_inicial_transform = camera.global_transform

##inicia a interacao exemplo: sentar e olhar para monitor
func iniciar_interacao():
	if tween_atual != null and tween_atual.is_valid():
		tween_atual.kill()
	em_transicao = true
	interagindo_com_tela = true
	interacao_gui.ativo = true
	interact_label.visible = false
	ponto_da_camera.visible = false
	Global.player_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	camera_inicial_transform = camera.global_transform
	tween_atual = create_tween()
	tween_atual.tween_property(camera, "global_transform", camera_monitor.global_transform, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_atual.connect("finished", Callable(self, "_on_tween_iniciar_interacao_finished"))

func _on_tween_iniciar_interacao_finished():
	em_transicao = false
	camera_monitor.current = true

##termina a interacao
func terminar_interacao():
	if tween_atual != null and tween_atual.is_valid():
		tween_atual.kill()
	em_transicao = true
	interagindo_com_tela = false
	interacao_gui.ativo = false
	interact_label.visible = false
	ponto_da_camera.visible = true
	Global.player_locked = false
	camera_monitor.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	tween_atual = create_tween()
	tween_atual.tween_property(camera, "global_transform", camera_inicial_transform, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_atual.connect("finished", Callable(self, "_on_tween_terminar_interacao_finished"))

func _on_tween_terminar_interacao_finished():
	em_transicao = false

func _input(event):
	if interagindo_com_tela or em_transicao:
		if event.is_action_pressed("ui_cancel"):
			terminar_interacao()
		return 

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * SENSIBILIDADE)
		camera.rotate_x(-event.relative.y * SENSIBILIDADE)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if event.is_action_pressed("Interacao"):
		if objeto_selecionado == null:
			if raycast.is_colliding():
				var collider = raycast.get_collider()
				if collider.is_in_group("pegavel"):
					pegar_objeto(collider)
				elif collider.is_in_group("tela_interativa"):
					iniciar_interacao()
		else:
			if raycast.is_colliding():
				var collider = raycast.get_collider()
				##segurando fita e mirando monitor inicia interaçao
				if collider.is_in_group("tela_interativa") and objeto_selecionado.is_in_group("fita"):
					iniciar_interacao()
				else:
					##se nao estiver mirando no monitor solta
					soltar_objeto()
			else:
				soltar_objeto()

func _physics_process(delta: float) -> void:
	##bloqueia movimento durante interacao ou transicao
	if interagindo_com_tela or em_transicao:
		velocity = Vector3.ZERO
		return 
###dadawdaw
	if not is_on_floor():
		velocity += get_gravity() * delta

	##movimento do player
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction and Global.player_locked == false:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	elif not labrinto and Global.Ta_no_jogo == false:
		Global.player_locked = true
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		rotation_degrees.y -= mouse.x * delta
		camera.rotation_degrees.x -= mouse.y * delta
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 80)
	##headbob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob) + Vector3(0, 0.5, 0)
	##exibir label de interacao quando olhar para objeto que seja interativo
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		interact_object.emit(collider)
		if collider.is_in_group("tela_interativa") or collider.is_in_group("pegavel") or \
		   (objeto_selecionado != null and objeto_selecionado.is_in_group("fita") and collider.is_in_group("tela_interativa")):
			interact_label.visible = true
		else:
			interact_label.visible = false
	else: 
		interact_object.emit(null)
		interact_label.visible = false
	##segurar objeto carregado na mao
	if objeto_selecionado != null:
		objeto_selecionado.global_transform = mao.global_transform
		objeto_selecionado.linear_velocity = Vector3.ZERO
		objeto_selecionado.angular_velocity = Vector3.ZERO
	move_and_slide()
##funcao para o movimento headbob
func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos
##pega o objeto em foco
func pegar_objeto(obj):
	objeto_selecionado = obj
	objeto_selecionado.rotation_degrees = Vector3.ZERO
	objeto_selecionado.angular_velocity = Vector3.ZERO
	objeto_selecionado.linear_velocity = Vector3.ZERO
	for child in objeto_selecionado.get_children():
		if child is CollisionShape3D:
			child.disabled = true
##solta o objeto selecionado
func soltar_objeto():
	if objeto_selecionado != null:
		for child in objeto_selecionado.get_children():
			if child is CollisionShape3D:
				child.disabled = false
	objeto_selecionado = null
