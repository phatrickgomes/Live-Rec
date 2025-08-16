extends CharacterBody3D

signal interact_object

@onready var camera_pivot: Node3D = $camera_pivot
@onready var camera: Camera3D = $camera_pivot/Camera3D
@onready var raycast = $camera_pivot/Camera3D/interacao
@onready var mao = $camera_pivot/Camera3D/CarryObjectMaker

var objeto_selecionado 
var forca_braco = 4 

const SPEED = 0.0000001
const JUMP_VELOCITY = 5.5
const SENSIBILIDADE = 0.003

var mouse = Vector2()
var HIGH_MOUSE_SPEED = 10
var LOW_MOUSE_SPEED = 2
var current_mouse_speed = HIGH_MOUSE_SPEED

var pickedobject

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * SENSIBILIDADE)
		camera.rotate_x(-event.relative.y * SENSIBILIDADE)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))
	

	if event.is_action_pressed("Interacao"):
		if raycast.is_colliding() and pickedobject == null:
			var collider = raycast.get_collider()
		if objeto_selecionado == null:
			pegar_objeto()
		else:
			soltar_objeto()

func _physics_process(delta: float) -> void:
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			current_mouse_speed = LOW_MOUSE_SPEED
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			current_mouse_speed = HIGH_MOUSE_SPEED
	if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		return
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (camera_pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	rotation_degrees.y -= mouse.x * current_mouse_speed * delta
	camera.rotation_degrees.x -= mouse.y * current_mouse_speed * delta
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -80,80)
		
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		interact_object.emit(collider)
	else: 
		interact_object.emit(null)
		
		
	if objeto_selecionado != null:
		objeto_selecionado.global_transform = mao.global_transform
		objeto_selecionado.linear_velocity = Vector3.ZERO
		objeto_selecionado.angular_velocity = Vector3.ZERO

	move_and_slide()
	mouse = Vector2()
	
func pegar_objeto():
	var collider = raycast.get_collider()
	if collider != null and collider is RigidBody3D:
		objeto_selecionado = collider
		objeto_selecionado.rotation_degrees = Vector3.ZERO
		objeto_selecionado.angular_velocity = Vector3.ZERO
		objeto_selecionado.linear_velocity = Vector3.ZERO
		var shape = objeto_selecionado.get_node("CollisionShape3D")
		if shape:
			shape.disabled = true


func soltar_objeto():
	if objeto_selecionado != null:
		var shape = objeto_selecionado.get_node("CollisionShape3D")
		if shape:
			shape.disabled = false
	objeto_selecionado = null
