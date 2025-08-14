extends CharacterBody3D

signal interact_object

## nós e referências
@onready var camera_pivot: Node3D = $camera_pivot
@onready var camera: Camera3D = $camera_pivot/Camera3D
@onready var camera_monitor: Camera3D = get_node_or_null("../GUI/Monitor")
@onready var camera_monitor2: Camera3D = get_node_or_null("../GUI/Monitor2")
@onready var raycast = $camera_pivot/Camera3D/interacao
@onready var mao = $camera_pivot/Camera3D/CarryObjectMaker
@onready var interacao_gui = $"../GUI"
@onready var interact_label: Label = $CanvasLayer/interact_label
@onready var ponto_da_camera = $Label
@onready var labrinto: Node3D = $".."

## variáveis principais
var objeto_selecionado = null
const SPEED = 4.0
const SENSIBILIDADE = 0.003
var mouse = Vector2()
var interagindo_com_tela = false
var em_transicao = false
var tween_atual: Tween = null
var camera_inicial_transform: Transform3D
var monitor_atual: int = 0 

## headbob
var t_bob: float = 0.0
var bob_freq: float = 2.0
var bob_amp: float = 0.07

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_inicial_transform = camera.global_transform

## interações
func iniciar_interacao_monitor1():
	if not camera_monitor: return
	_iniciar_transicao_para(camera_monitor, 1)

func iniciar_interacao_monitor2():
	if not camera_monitor2: 
		print("Monitor 2 não encontrado!")
		return
	_iniciar_transicao_para(camera_monitor2, 2)

func _iniciar_transicao_para(target_camera: Camera3D, monitor_id: int):
	if em_transicao: return
	if tween_atual and tween_atual.is_valid():
		tween_atual.kill()
	if monitor_atual == 0:
		camera_inicial_transform = camera.global_transform
	em_transicao = true
	interagindo_com_tela = true
	monitor_atual = monitor_id
	interacao_gui.ativo = true
	interact_label.visible = false
	ponto_da_camera.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tween_atual = create_tween()
	tween_atual.tween_property(camera, "global_transform", target_camera.global_transform, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_atual.connect("finished", Callable(self, "_on_tween_monitor_finished"))
	if Global.Ta_no_jogo:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _on_tween_monitor_finished():
	em_transicao = false

func terminar_interacao():
	if em_transicao: return
	if tween_atual and tween_atual.is_valid():
		tween_atual.kill()
	em_transicao = true
	interagindo_com_tela = false
	monitor_atual = 0
	interacao_gui.ativo = false
	interact_label.visible = false
	ponto_da_camera.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	tween_atual = create_tween()
	tween_atual.tween_property(camera, "global_transform", camera_inicial_transform, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_atual.connect("finished", Callable(self, "_on_tween_voltar_jogo_finished"))
	Global.Ta_no_jogo = false
	

func _on_tween_voltar_jogo_finished():
	em_transicao = false

## entrada
func _input(event):
	if em_transicao: return
	if event.is_action_pressed("ui_cancel"):
		if monitor_atual != 0:
			terminar_interacao()
		return
	if event.is_action_pressed("F"):
		if monitor_atual == 1:
			iniciar_interacao_monitor2()
		elif monitor_atual == 2:
			iniciar_interacao_monitor1()
	if interagindo_com_tela:
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
					iniciar_interacao_monitor1()
		else:
			if raycast.is_colliding():
				var collider = raycast.get_collider()
				if collider.is_in_group("tela_interativa") and objeto_selecionado.is_in_group("fita"):
					iniciar_interacao_monitor1()
				else:
					soltar_objeto()

func _physics_process(delta: float) -> void:
	if interagindo_com_tela or em_transicao:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction and Global.Ta_no_jogo == false:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		rotation_degrees.y -= mouse.x * delta
		camera.rotation_degrees.x -= mouse.y * delta
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 80)

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob) + Vector3(0, 0.5, 0)

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

	if objeto_selecionado != null:
		objeto_selecionado.global_transform = mao.global_transform
		objeto_selecionado.linear_velocity = Vector3.ZERO
		objeto_selecionado.angular_velocity = Vector3.ZERO

	move_and_slide()

func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

func pegar_objeto(obj):
	objeto_selecionado = obj
	objeto_selecionado.rotation_degrees = Vector3.ZERO
	objeto_selecionado.angular_velocity = Vector3.ZERO
	objeto_selecionado.linear_velocity = Vector3.ZERO
	for child in objeto_selecionado.get_children():
		if child is CollisionShape3D:
			child.disabled = true

func soltar_objeto():
	if objeto_selecionado != null:
		for child in objeto_selecionado.get_children():
			if child is CollisionShape3D:
				child.disabled = false
	objeto_selecionado = null
