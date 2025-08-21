extends CharacterBody2D

@export var speed: float = 500
@export var tiro_scene: PackedScene = preload("res://tiro.tscn")

@onready var vida_label = $"../vida_label"


var vida_atual = 3

func _ready():
	atualizar_vida_hud()


func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	input_vector = input_vector.normalized()

	velocity = input_vector * speed
	move_and_slide()

	if Input.is_action_just_pressed("tiro"):
		atirar()

func atirar() -> void:
	var tiro = tiro_scene.instantiate()
	var direcao = Vector2.RIGHT.rotated(rotation)
	tiro.global_position = global_position + direcao * 80
	tiro.rotation = rotation 
	get_parent().add_child(tiro)

func levar_dano(dano: int) -> void:
	vida_atual -= dano
	if vida_atual < 0:
		vida_atual = 0
	atualizar_vida_hud()
	if vida_atual <= 0:
		morrer()

func morrer() -> void:
	print("voce morreu")
	get_tree().reload_current_scene()  

func _on_hurt_box_area_entered(area):
	if area.is_in_group("tiro_jamv"):
		print("tomando dano")
		levar_dano(1)
		
func atualizar_vida_hud():
	if vida_label:
		vida_label.text = str(vida_atual)
