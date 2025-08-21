extends CharacterBody2D

@export var speed: float = 200
@export var tiro_scene: PackedScene
@export var shoot_interval: float = 0.04

@export var max_health: int = 100
var current_health: int = max_health

@onready var vida = $ProgressBar


var shoot_timer: float = 0.0
var time: float = 0.0

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	time += delta
	var offset_x = sin(time * 2.0) * 70 
	var offset_y = cos(time * 3.0) * 70
	velocity = Vector2(offset_x, offset_y).normalized() * speed
	move_and_slide()
	
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		atirar()
		shoot_timer = shoot_interval

func atirar() -> void:
	var tiro = tiro_scene.instantiate()
	var distancia_frente = -150
	var offset = Vector2.RIGHT.rotated(rotation) * distancia_frente
	tiro.global_position = global_position + offset
	get_parent().add_child(tiro)

func take_damage(amount: int) -> void:
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	update_health_bar()
	if current_health <= 0:
		die()

func update_health_bar() -> void:
	if vida:
		vida.value = current_health

func die() -> void:
	get_tree().reload_current_scene()
	
func _on_hurtbox_area_entered(area):
	if area.is_in_group("tiro"):  
		take_damage(1)
		update_health_bar()
		print("acertou")
