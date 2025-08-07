extends CharacterBody3D

signal interact_object
@onready var camera_pivot: Node3D = $camera_pivot
@onready var camera = $camera_pivot/Camera3D
@onready var camera_monitor = get_node_or_null("../GUI/Monitor")
@onready var raycast = $camera_pivot/Camera3D/interacao
@onready var mao = $camera_pivot/Camera3D/CarryObjectMaker
@onready var interacao_gui = $"../GUI"
@onready var interact_label: Label = $CanvasLayer/interact_label

var objeto_selecionado 
var forca_braco = 4 

const SPEED = 5.5
const SENSIBILIDADE = 0.003

var mouse = Vector2()

var interagindo_com_tela = false

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func iniciar_interacao():
	camera_monitor.current = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	interagindo_com_tela = true
	interacao_gui.ativo = true
	interact_label.visible = false
	if Global.Ta_no_jogo == true:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func terminar_interacao():
	camera_monitor.current = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	interagindo_com_tela = false
	interacao_gui.ativo = false
	interact_label.visible = false
	Global.Ta_no_jogo == false
		#vendo se ele esta interagindo com o monitor e quando aperta ESC sair do monitor
func _input(event):
	if interagindo_com_tela:
		if event.is_action_pressed("ui_cancel"):
			terminar_interacao()
		return 
	##camera do jogador
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * SENSIBILIDADE)
		camera.rotate_x(-event.relative.y * SENSIBILIDADE)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
		##verificando se a tecla foi apertado e vai funcionar
	if event.is_action_pressed("Interacao"):
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider.is_in_group("tela_interativa"):
				iniciar_interacao()
				return
		if objeto_selecionado == null:
			pegar_objeto()
		else:
			soltar_objeto()

func _physics_process(delta: float) -> void:
		##verifica no começo do jogo se o player esta interagindo
	if interagindo_com_tela:
		return 
		##apenas a movimentaçao
	if not is_on_floor():
		velocity += get_gravity() * delta
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		rotation_degrees.y -= mouse.x * delta
		camera.rotation_degrees.x -= mouse.y * delta
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80, 80)
	
		##interaçao dos raycast com os objetos
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		interact_object.emit(collider)
		if collider.is_in_group("tela_interativa"):
			interact_label.visible = true
		else:
			interact_label.visible = false
	else: 
		interact_object.emit(null)
		interact_label.visible = false
   ##interaçao com a cenoura/fita
	if objeto_selecionado != null:
		objeto_selecionado.global_transform = mao.global_transform
		objeto_selecionado.linear_velocity = Vector3.ZERO
		objeto_selecionado.angular_velocity = Vector3.ZERO

	move_and_slide()

func pegar_objeto():
	var collider = raycast.get_collider()
	if collider != null and collider is RigidBody3D:
		objeto_selecionado = collider
		objeto_selecionado.rotation_degrees = Vector3.ZERO
		objeto_selecionado.angular_velocity = Vector3.ZERO
		objeto_selecionado.linear_velocity = Vector3.ZERO
		var shape = objeto_selecionado.get_node("cenoura")
		var shape2 = objeto_selecionado.get_node("fita_collision")
		if shape:
			shape.disabled = true
		if shape:
			shape2.disabled = true

func soltar_objeto():
	if objeto_selecionado != null:
		var shape = objeto_selecionado.get_node("cenoura")
		var shape2 = objeto_selecionado.get_node("fita_collision")
		if shape:
			shape.disabled = false
		if shape:
			shape2.disabled = false
	objeto_selecionado = null
