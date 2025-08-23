extends CharacterBody3D

signal interact_object

## NÓS E REFERÊNCIAS
@onready var camera_pivot: Node3D = $camera_pivot
@onready var camera: Camera3D = $camera_pivot/Camera3D
@onready var camera_monitor: Camera3D = get_node_or_null("../GUI/Monitor")
@onready var camera_monitor2: Camera3D = get_node_or_null("../GUI/Monitor2")
@onready var camera_folha: Camera3D = $"../camera_folha/camera_folha"
@onready var camera_folha_2: Camera3D = $"../camera_folha/camera_folha2/camera_folha2"
@onready var camera_folha_3 = $"../camera_folha3/camera_folha3"




@onready var raycast = $camera_pivot/Camera3D/interacao
@onready var mao = $camera_pivot/Camera3D/CarryObjectMaker
@onready var interacao_gui = $"../GUI"
@onready var interact_label: Label = $CanvasLayer/interact_label
@onready var ponto_da_camera = $Label
@onready var main_scene_3d: Node3D = $"."
@onready var interact_monitor: Label = $CanvasLayer/interact_monitor
@onready var color_rect_MONITOR: ColorRect = $CanvasLayer/ColorRect
@onready var audio_de_fundo = $audio_de_fundo
@onready var corvo = $"../corvo"
@onready var passos_som = $passos_som

## VARIÁVEIS PRINCIPAIS
var objeto_selecionado = null
const SPEED = 4.0
const SENSIBILIDADE = 0.003
var mouse = Vector2()
var interagindo_com_tela = false
var interagindo_com_folha = false
var em_transicao = false
var tween_atual: Tween = null
var camera_inicial_transform: Transform3D
var saved_pivot_rot: Vector3
var saved_cam_rot: Vector3
var monitor_atual: int = 0 

## HEADBOB
var t_bob: float = 0.0
var bob_freq: float = 2.0
var bob_amp: float = 0.07

func reset_player():
	velocity = Vector3.ZERO
	objeto_selecionado = null
	interagindo_com_tela = false
	interagindo_com_folha = false
	em_transicao = false
	monitor_atual = 0
	

	if interacao_gui and interacao_gui.has_method("set_ativo"):
		interacao_gui.ativo = false
	

	camera_pivot.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	

	if camera and camera_inicial_transform:
		camera.global_transform = camera_inicial_transform
	
	# Reset FORÇADO do input e mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Input.warp_mouse(Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2))
	
	# Reset da UI - DESATIVA TUDO
	interact_label.visible = false
	interact_monitor.visible = false
	color_rect_MONITOR.visible = false
	ponto_da_camera.visible = true
	

	if tween_atual and tween_atual.is_valid():
		tween_atual.kill()
		tween_atual = null
	
	
	em_transicao = false
	
	print("Reset completo - Forçado para modo livre")

func _ready():
	# Sempre reseta completamente
	reset_player()
	
	# Se veio de uma morte, mostra mensagem e reseta o flag
	if "player_died" in Global:
		if Global.player_died:
			print("Streamer resetado após morte no labirinto")
			Global.player_died = false
	
	PlayerManager.register_main_player(self)
	add_to_group("player")
	interact_monitor.visible = false
	color_rect_MONITOR.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_inicial_transform = camera.global_transform
	
	# Garante que o mouse está capturado e centralizado
	Input.warp_mouse(Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2))
	
	set_process_input(true)
	set_physics_process(true)
	
## INTERAÇÕES
func iniciar_interacao_monitor1():
	if not camera_monitor: return
	_iniciar_transicao_para(camera_monitor, 1)

func iniciar_interacao_monitor2():
	if not camera_monitor2: 
		print("Monitor 2 não encontrado!")
		return
	_iniciar_transicao_para(camera_monitor2, 2)

func iniciar_interacao_folha():
	if not camera_folha: return
	_iniciar_transicao_para_folha(camera_folha)

func iniciar_interacao_folha2():
	if not camera_folha_2: return
	_iniciar_transicao_para_folha(camera_folha_2)
	
func iniciar_interacao_folha3():
	if not camera_folha_3: 
		print("Camera Folha 3 não encontrada!")
		return
	_iniciar_transicao_para_folha(camera_folha_3)

func _iniciar_transicao_para(target_camera: Camera3D, monitor_id: int):
	Global.Ta_no_jogo = true
	if em_transicao: return
	if tween_atual and tween_atual.is_valid():
		tween_atual.kill()
	if monitor_atual == 0:
		camera_inicial_transform = camera.global_transform
		saved_pivot_rot = camera_pivot.rotation
		saved_cam_rot = camera.rotation
	em_transicao = true
	interagindo_com_tela = true
	monitor_atual = monitor_id
	interacao_gui.ativo = true
	interact_label.visible = false
	ponto_da_camera.visible = true
	interact_monitor.visible = true
	color_rect_MONITOR.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tween_atual = create_tween()
	tween_atual.tween_property(camera, "global_transform", target_camera.global_transform, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_atual.connect("finished", Callable(self, "_on_tween_monitor_finished"))
	if audio_de_fundo:
		audio_de_fundo.stop()
	if corvo:
		corvo.stop()

func _iniciar_transicao_para_folha(target_camera: Camera3D):
	Global.Ta_no_jogo = true
	if em_transicao: return
	if tween_atual and tween_atual.is_valid():
		tween_atual.kill()
	camera_inicial_transform = camera.global_transform
	saved_pivot_rot = camera_pivot.rotation
	saved_cam_rot = camera.rotation
	em_transicao = true
	interagindo_com_folha = true
	interact_label.visible = false
	ponto_da_camera.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tween_atual = create_tween()
	tween_atual.tween_property(camera, "global_transform", target_camera.global_transform, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_atual.connect("finished", Callable(self, "_on_tween_folha_finished"))

func _on_tween_monitor_finished():
	em_transicao = false

func _on_tween_folha_finished():
	em_transicao = false

func terminar_interacao():
	if em_transicao: return
	if tween_atual and tween_atual.is_valid():
		tween_atual.kill()
	em_transicao = true
	
	if interagindo_com_tela:
		interagindo_com_tela = false
		monitor_atual = 0
		interacao_gui.ativo = false
		interact_monitor.visible = false
		color_rect_MONITOR.visible = false
	elif interagindo_com_folha:
		interagindo_com_folha = false
	interact_label.visible = false
	ponto_da_camera.visible = true
	
	if audio_de_fundo:
		audio_de_fundo.play()
	if corvo:
		corvo.stop()
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	tween_atual = create_tween()
	tween_atual.tween_property(camera, "global_transform", camera_inicial_transform, 1.0)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_atual.connect("finished", Callable(self, "_on_tween_voltar_jogo_finished"))
	Global.Ta_no_jogo = false

func _on_tween_voltar_jogo_finished():
	em_transicao = false
	camera_pivot.rotation = saved_pivot_rot
	camera.rotation = saved_cam_rot

## INPUT
func _input(event):
	if em_transicao: return
	
	if event.is_action_pressed("ui_cancel"):
		if monitor_atual != 0 or interagindo_com_folha:
			terminar_interacao()
		return
	
	if event.is_action_pressed("F"):
		if monitor_atual == 1:
			iniciar_interacao_monitor2()
		elif monitor_atual == 2:
			iniciar_interacao_monitor1()
	
	if interagindo_com_tela or interagindo_com_folha:
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
				elif collider.is_in_group("folha"):
					iniciar_interacao_folha()
				elif collider.is_in_group("folha2"):
					iniciar_interacao_folha2()
				elif collider.is_in_group("folha3"):
					iniciar_interacao_folha3()
		else:
			if raycast.is_colliding():
				var collider = raycast.get_collider()
				if collider.is_in_group("tela_interativa") and objeto_selecionado.is_in_group("fita"):
					iniciar_interacao_monitor1()
				else:
					soltar_objeto()

## PHYSICS PROCESS
func _physics_process(delta: float) -> void:
	if interagindo_com_tela or interagindo_com_folha or em_transicao:
		velocity = Vector3.ZERO
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction and Global.Ta_no_jogo == false:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		if is_on_floor() and not passos_som.playing:
			passos_som.play()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

		if passos_som.playing:
			passos_som.stop()

	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob) + Vector3(0, 0.5, 0)

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		interact_object.emit(collider)
		if collider.is_in_group("tela_interativa") or collider.is_in_group("pegavel") or \
		   collider.is_in_group("folha") or collider.is_in_group("folha2") or collider.is_in_group("folha3") or \
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
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not (interagindo_com_tela or interagindo_com_folha or em_transicao):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		Input.warp_mouse(Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2))
	
	if interagindo_com_tela or interagindo_com_folha or em_transicao:
		velocity = Vector3.ZERO
		return
## HEADBOB
func _headbob(time: float) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * bob_freq) * bob_amp
	pos.x = cos(time * bob_freq / 2) * bob_amp
	return pos

## PEGAR OBJETO
func pegar_objeto(obj):
	objeto_selecionado = obj
	objeto_selecionado.rotation_degrees = Vector3.ZERO
	objeto_selecionado.angular_velocity = Vector3.ZERO
	objeto_selecionado.linear_velocity = Vector3.ZERO
	for child in objeto_selecionado.get_children():
		if child is CollisionShape3D:
			child.disabled = true

## SOLTAR OBJETO
func soltar_objeto():
	if objeto_selecionado != null:
		for child in objeto_selecionado.get_children():
			if child is CollisionShape3D:
				child.disabled = false
	objeto_selecionado = null
